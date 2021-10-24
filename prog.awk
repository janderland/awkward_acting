function error_msg(msg) {
  print "ERR! " msg > "/dev/stderr"
}

function debug_msg(msg) {
  print "DEBUG: " msg > "/dev/stderr"
}

function run(cmd) {
  if ((_code = system(cmd)) != 0) {
    error_msg("shell command failed: " cmd)
    exit _code
  }
}

function run_out(cmd) {
  cmd | getline _output
  if ((_code = close(cmd)) != 0) {
    error_msg("shell command failed: " cmd)
    exit _code
  }
  return _output
}

function run_code(cmd) {
  cmd | getline _output
  if ((_code = close(cmd)) != 0) {
    error_msg("shell command failed: " cmd)
  }
  return _code
}

function under_limit(id, msg) {
  if(_count[id] < _limit[id]) {
    _count[id] = _count[id] + 1
    return 1
  } else {
    print msg
    return 0
  }
}

BEGIN {
  _count["input"] = 0
  _limit["input"] = 4

  out_file = "out.txt"
  err_file = "err.txt"
}

$1 == "input" {
  if (! $2) {
    error_msg("message missing 1st argument: " $0)
    exit 1
  }

  if (under_limit("input", $0)) {
    file = run_out("mktemp")
    if (run_code("set -x; curl -Lso " file " " $2) != 0) {
      printf("err failed to download %s\n", $2)
    } else {
      printf("process %s %s\n", $2, file)
    }
  }
}

$1 == "process" {
  if (! $2) {
    error_msg("message missing 1st argument: " $0)
    exit 1
  }
  if (! $3) {
    error_msg("message missing 2nd argument: " $0)
    exit 1
  }

  if (run_code("set -x; magick jpeg:" $3 " -print '%b' null:") != 0) {
    printf("err failed to process %s\n", $3)
  } else {
    printf("out %s %s %s\n", $2, $3, _output)
  }
}

$1 == "out" {
  if (! $2) {
    error_msg("message missing 1st argument: " $0)
    exit 1
  }
  if (! $3) {
    error_msg("message missing 2nd argument: " $0)
    exit 1
  }
  if (! $4) {
    error_msg("message missing 3nd argument: " $0)
    exit 1
  }

  printf("%s %s %s\n", $2, $3, $4) >> out_file
}

$1 == "err" {
  msg = substr($0, length($1)+2)
  printf("%s\n", msg) >> err_file
}
