# {{{ -- meta

HOSTARCH  := x86_64# on travis.ci
ARCH      := $(shell uname -m | sed "s_armv7l_armhf_")# armhf/x86_64 auto-detect on build and run
OPSYS     := alpine
SHCOMMAND := /bin/bash
SVCNAME   := s6
USERNAME  := woahbase

DOCKERSRC := $(OPSYS)-base#
DOCKEREPO := $(USERNAME)/$(OPSYS)-$(SVCNAME)
IMAGETAG  := $(DOCKEREPO):$(ARCH)

# -- }}}

# {{{ -- flags

BUILDFLAGS := --rm --force-rm -f $(CURDIR)/Dockerfile_$(ARCH) -t $(IMAGETAG) \
	--build-arg ARCH=$(ARCH) \
	--build-arg BUILD_DATE=$(shell date -u +"%Y-%m-%dT%H:%M:%SZ") \
	--build-arg DOCKEREPO=$(DOCKEREPO) \
	--build-arg DOCKERSRC=$(DOCKERSRC) \
	--build-arg USERNAME=$(USERNAME) \
	--build-arg VCS_REF=$(shell git rev-parse --short HEAD)

CACHEFLAGS := --no-cache=true --pull
MOUNTFLAGS := #
NAMEFLAGS  := --name docker_$(SVCNAME) --hostname $(SVCNAME)
OTHERFLAGS := # -v /etc/hosts:/etc/hosts:ro -v /etc/localtime:/etc/localtime:ro -e TZ=Asia/Kolkata
PORTFLAGS  := #
PROXYFLAGS := --build-arg http_proxy=$(http_proxy) --build-arg https_proxy=$(https_proxy) --build-arg no_proxy=$(no_proxy)

RUNFLAGS   := -c 64 -m 32m # -e PGID=$(shell id -g) -e PUID=$(shell id -u)

# -- }}}

# {{{ -- docker targets

all : run

build :
	echo "Building for $(ARCH) from $(HOSTARCH)";
	if [ "$(ARCH)" != "$(HOSTARCH)" ]; then make regbinfmt ; fi;
	docker build $(BUILDFLAGS) $(CACHEFLAGS) $(PROXYFLAGS) .

clean :
	docker images | awk '(NR>1) && ($$2!~/none/) {print $$1":"$$2}' | grep $(DOCKEREPO) | xargs -n1 docker rmi

logs :
	docker logs -f docker_$(SVCNAME)

pull :
	docker pull $(IMAGETAG)

push :
	docker push $(IMAGETAG)

restart :
	docker ps -a | grep 'docker_$(SVCNAME)' -q && docker restart docker_$(SVCNAME) || echo "Service not running.";

rm : stop
	docker rm -f docker_$(SVCNAME)

run :
	docker run --rm -it $(NAMEFLAGS) $(RUNFLAGS) $(PORTFLAGS) $(MOUNTFLAGS) $(OTHERFLAGS) $(IMAGETAG)

rshell :
	docker exec -u root -it docker_$(SVCNAME) $(SHCOMMAND)

shell :
	docker exec -it docker_$(SVCNAME) $(SHCOMMAND)

stop :
	docker stop -t 2 docker_$(SVCNAME)

test :
	echo "__TODO__";
	# docker run --rm -it $(NAMEFLAGS) $(RUNFLAGS) $(PORTFLAGS) $(MOUNTFLAGS) $(OTHERFLAGS) $(IMAGETAG) which s6-hostname

# -- }}}

# {{{ -- other targets

regbinfmt :
	docker run --rm --privileged multiarch/qemu-user-static:register --reset

# -- }}}
