docker-cedarish-to-rocket-herokuish
===================================

This is an experiment to "port" the use of [cedarish](https://github.com/progrium/cedarish) using docker in [deis](https://github.com/deis/deis)
to [herokuish](https://github.com/gliderlabs/herokuish) using [rocket](https://github.com/coreos/rocket) to build apps in a heroku like way

steps:
1. build the application inside docker using herokuish
2. extract the "compiled" application (tgz)
3. convert deis/slugrunner docker image required to run apps (slugrunner.aci)
4. build an image for the compiled app using slugrunner.aci as dependency

TODO:
[] - create a rocket herokuish image (with all the required dependencies to build apps)
[] - remove docker "dependency" :P
[] - ...
[] - ...

