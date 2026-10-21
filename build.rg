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
      task bundle =  "mkdir -p target target/bundles && for m in socket argon2id crypto posix io str test; do ridgunc build --lib src/main/ridgun/lib/$m.rg -o target/$m.rglib && cp target/$m.rglib target/bundles/$m.rglib && cp target/$m.rglib target/$m.rgc && ridgunc build --so src/main/ridgun/lib/$m.rg -o target/lib$m.so; done"
