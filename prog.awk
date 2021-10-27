BEGIN {
  INPUT_COUNT = 0
  INPUT_LIMIT = 4
  OUT_FILE = "out.txt"
  ERR_FILE = "err.txt"
}


# The input actor receives URLs from run.sh, downloads them,
# and sends the names of the downloaded files to the process
# actor.

$1 == "input" {
  url = $2

  if (INPUT_COUNT++ > INPUT_LIMIT) {
    send_input_msg(url)
    next
  }

  file = shell_return_stdout("mktemp")

  if (shell_return_code("set -x; curl -Lso " file " " url) != 0) {
    send_err_msg("failed to download " url)
    next
  }

  send_process_msg(url, file)
}


# The process actor receives filenames which are assumed to be JPEGS,
# uses Image Magick to calculate the top-three colors of the images,
# and sends the results to the out actor.

$1 == "process" {
  url = $2
  file = $3

  if (shell_return_code("set -x; magick jpeg:" $3 " -print '%b' null:") != 0) {
    send_err_msg("failed to process " $2)
  } else {
    send_out_msg(url, file, SHELL_OUTPUT)
  }
}


# The out actor prints the final output of the program to the
# output file.

$1 == "out" {
  url = $2
  file = $3
  result = $4
  write_result(url, file, result)
}


# The err actor prints any errors encountered along the way
# to the error file.

$1 == "err" {
  write_error(substr($0, length($1)+2))
}



function send_input_msg(url) {
  printf("input %s\n", url)
}

function send_process_msg(url, file) {
  printf("process %s %s\n", url, file)
}

function send_out_msg(url, file, result) {
  printf("out %s %s %s\n", url, file, result)
}

function send_err_msg(msg) {
  printf("err %s\n", msg)
}

function log_error(msg) {
  print "ERR! " msg > "/dev/stderr"
}

function write_result(url, file, result) {
  printf("%s %s %s\n", url, file, result) >> OUT_FILE
}

function write_error(msg) {
  printf("%s\n", msg) >> ERR_FILE
}

function shell(cmd) {
  cmd | getline SHELL_OUTPUT
  if ((SHELL_CODE = close(cmd)) != 0) {
    log_error("shell command failed: " cmd)
  }
}

function shell_return_code(cmd) {
  shell(cmd)
  return SHELL_CODE
}

function shell_return_stdout(cmd) {
  shell(cmd)
  if (SHELL_CODE != 0) {
    exit SHELL_CODE
  }
  return SHELL_OUTPUT
}
