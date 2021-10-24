function error_msg(msg) {
  print "ERR! " msg > "/dev/stderr"
}

function debug_msg(msg) {
  print "DEBUG: " msg > "/dev/stderr"
}

function run(cmd) {
  if ((RUN_CODE = system(cmd)) != 0) {
    error_msg("shell command failed: " cmd)
    exit RUN_CODE
  }
}

function run_out(cmd) {
  cmd | getline RUN_OUTPUT
  if ((RUN_CODE = close(cmd)) != 0) {
    error_msg("shell command failed: " cmd)
    exit RUN_CODE
  }
  return RUN_OUTPUT
}

function run_code(cmd) {
  cmd | getline RUN_OUTPUT
  if ((RUN_CODE = close(cmd)) != 0) {
    error_msg("shell command failed: " cmd)
  }
  return RUN_CODE
}

function actor_should_run(id, msg, expected_field_count) {
  if (expected_field_count != -1 && NF - 1 != expected_field_count) {
    error_msg("invalid message: " msg)
    exit 1
  }
  if (ACTOR_RUN_LIMIT[id] == 0 || ACTOR_RUN_COUNT[id] < ACTOR_RUN_LIMIT[id]) {
    ACTOR_RUN_COUNT[id] = ACTOR_RUN_COUNT[id] + 1
    return 1
  } else {
    print msg
    return 0
  }
}

BEGIN {
  ACTOR_RUN_COUNT["input"]   = 0
  ACTOR_RUN_COUNT["process"] = 0
  ACTOR_RUN_COUNT["out"]     = 0
  ACTOR_RUN_COUNT["err"]     = 0

  ACTOR_RUN_LIMIT["input"]   = 4
  ACTOR_RUN_LIMIT["process"] = 0
  ACTOR_RUN_LIMIT["out"]     = 0
  ACTOR_RUN_LIMIT["err"]     = 0

  out_file = "out.txt"
  err_file = "err.txt"
}

$1 == "input" {
  if (actor_should_run("input", $0, 1)) {
    file = run_out("mktemp")
    if (run_code("set -x; curl -Lso " file " " $2) != 0) {
      printf("err failed to download %s\n", $2)
    } else {
      printf("process %s %s\n", $2, file)
    }
  }
}

$1 == "process" {
  if (actor_should_run("process", $0, 2)) {
    if (run_code("set -x; magick jpeg:" $3 " -print '%b' null:") != 0) {
      printf("err failed to process %s\n", $3)
    } else {
      printf("out %s %s %s\n", $2, $3, RUN_OUTPUT)
    }
  }
}

$1 == "out" {
  if (actor_should_run("out", $0, 3)) {
    printf("%s %s %s\n", $2, $3, $4) >> out_file
  }
}

$1 == "err" {
  if (actor_should_run("err", $0, -1)) {
    msg = substr($0, length($1)+2)
    printf("%s\n", msg) >> err_file
  }
}
