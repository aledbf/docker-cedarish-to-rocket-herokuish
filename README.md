docker-cedarish-to-rocket-herokuish
===================================

This is an experiment to "port" the use of [cedarish](https://github.com/progrium/cedarish) using docker in [deis](https://github.com/deis/deis) to [herokuish](https://github.com/gliderlabs/herokuish) using [rocket](https://github.com/coreos/rocket) to build apps ala Heroku

steps:

1. build the application inside docker using herokuish
2. extract the "compiled" application (tgz)
3. convert heroku/cedar:14 docker image required to run apps (slugrunner.aci)
4. build an image for the compiled app using slugrunner.aci as dependency
5. launch a nginx container (as "registry")
6. launch a docker container with rocket to download and run the application
