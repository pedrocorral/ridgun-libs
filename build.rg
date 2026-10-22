-- build.rg — Ridgun Library Project Definition

fn :: project name => String
      project name =  "ridgun-libs"

fn :: project kind => String
      project kind =  "lib"

fn :: project version => String
      project version =  "0.1.0"

fn :: main entry => String
      main entry =  "src/main/ridgun/lib/socket.rg"

fn :: source dir => String
      source dir =  "src/main/ridgun"

fn :: test dir => String
      test dir =  "src/test/ridgun"

fn :: target dir => String
      target dir =  "target"

fn :: dependencies => [String]
      dependencies =  []

fn :: task bundle => String
      task bundle =  "mkdir -p target target/bundles && rm -f target/socket.rglib target/argon2id.rglib target/crypto.rglib target/posix.rglib target/io.rglib target/str.rglib target/test.rglib target/math.rglib target/list.rglib target/codec.rglib target/cli.rglib target/path.rglib target/time.rglib target/log.rglib target/glob.rglib target/uuid.rglib target/http.rglib && for m in socket argon2id crypto posix io str test math list codec cli path time log glob uuid http; do ridgunc build --lib src/main/ridgun/lib/$m.rg -o target/bundles/$m.rglib && cp target/bundles/$m.rglib target/$m.rgc && ridgunc build --so src/main/ridgun/lib/$m.rg -o target/lib$m.so; done"
