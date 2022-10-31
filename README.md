# Example Typescript Node App

Simple fastify node app in typescript with nix builders. 

See [my blog post](https://johns.codes/blog/building-typescript-node-apps-with-nix) for more info

To build/run
```sh
nix build
./result/bin/ts-node-nix
```

Then you should be able to hit `GET localhost:8080/ping`
