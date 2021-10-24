function errf(msg) {
  print "ERR! " msg > "/dev/stderr"
}

function run(cmd) {
  if ((_code = system(cmd)) != 0) {
    errf("shell command failed: " cmd)
    exit _code
  }
}

function run_out(cmd) {
  cmd | getline _output
  if ((_code = close(cmd)) != 0) {
    errf("shell command failed: " cmd)
    exit _code
  }
  return _output
}

function run_code(cmd) {
  cmd | getline _output
  if ((_code = close(cmd)) != 0) {
    errf("shell command failed: " cmd)
  }
  return _code
}

$1 == "input" {
  if (! $2) {
    errf("message missing 1st argument: " $0)
    exit 1
  }

  file = run_out("mktemp")
  if (run_code("set -x; curl -Lso " file " " $2) != 0) {
    errf("failed to download " $2)
  } else {
    printf("process %s %s\n", $2, file)
  }
}

$1 == "process" {
  if (! $2) {
    errf("message missing 1st argument: " $0)
    exit 1
  }
  if (! $3) {
    errf("message missing 2nd argument: " $0)
    exit 1
  }

  if (run_code("set -x; magick jpeg:" $3 " -print '%b' null:") != 0) {
    errf("failed to process " $3)
  } else {
    printf("out %s %s %s\n", $2, $3, _output)
  }
}

$1 == "out" {
  if (! $2) {
    errf("message missing 1st argument: " $0)
    exit 1
  }
  if (! $3) {
    errf("message missing 2nd argument: " $0)
    exit 1
  }
  if (! $4) {
    errf("message missing 3nd argument: " $0)
    exit 1
  }

  print $2 " " $3 " " $4 > "/dev/stderr"
}
