ITERATION=1.lru
PREFIX=/usr/local
LICENSE=GPL-3.0
VENDOR="Free Software Foundation"
MAINTAINER="Ryan Parman"
DESCRIPTION="The GNU Compiler Collection includes front ends for C, C++, Objective-C, Fortran, Ada, and Go, as well as libraries for these languages."
URL=https://gcc.gnu.org
ACTUALOS=$(shell osqueryi "select * from os_version;" --json | jq -r ".[].name")
EL=$(shell if [[ "$(ACTUALOS)" == "Amazon Linux AMI" ]]; then echo alami; else echo el; fi)
RHEL=$(shell [[ -f /etc/centos-release ]] && rpm -q --queryformat '%{VERSION}' centos-release)

#-------------------------------------------------------------------------------

all:
	@echo "Run 'make gcc6' or 'make gcc7'."

#-------------------------------------------------------------------------------

.PHONY: gcc6
gcc6: gcc6-vars info clean install-deps gcc-compile install-tmp package move

.PHONY: gcc7
gcc7: gcc7-vars info clean install-deps gcc-compile install-tmp package move

#-------------------------------------------------------------------------------

.PHONY: gcc6-vars
gcc6-vars:
	$(eval NAME=gcc6)
	$(eval VERSION=6.4.0)

.PHONY: gcc7-vars
gcc7-vars:
	$(eval NAME=gcc7)
	$(eval VERSION=7.2.0)

#-------------------------------------------------------------------------------

.PHONY: info
info:
	@ echo "NAME:        $(NAME)"
	@ echo "VERSION:     $(VERSION)"
	@ echo "ITERATION:   $(ITERATION)"
	@ echo "PREFIX:      $(PREFIX)"
	@ echo "LICENSE:     $(LICENSE)"
	@ echo "VENDOR:      $(VENDOR)"
	@ echo "MAINTAINER:  $(MAINTAINER)"
	@ echo "DESCRIPTION: $(DESCRIPTION)"
	@ echo "URL:         $(URL)"
	@ echo "OS:          $(ACTUALOS)"
	@ echo "EL:          $(EL)"
	@ echo "RHEL:        $(RHEL)"
	@ echo " "

#-------------------------------------------------------------------------------

.PHONY: clean
clean:
	rm -Rf /tmp/installdir* gcc* gmon.out

#-------------------------------------------------------------------------------

.PHONY: install-deps
install-deps:
	yum -y install \
		autoconf \
		autogen \
		automake \
		binutils \
		bzip2-devel \
		dejagnu \
		diffutils \
		flex-devel \
		gawk \
		gcc \
		gcc-c++ \
		gcc-gnat \
		gettext-devel \
		gmp-devel \
		gperf \
		guile-devel \
		gzip \
		libmpc-devel \
		m4 \
		make \
		mpfr \
		patch \
		perl \
		python27 \
		tar \
		tcl-devel \
		texinfo-tex \
	;

#-------------------------------------------------------------------------------

.PHONY: gcc-compile
gcc-compile:
	wget http://mirrors-usa.go-parts.com/gcc/releases/gcc-$(VERSION)/gcc-$(VERSION).tar.bz2;
	tar jxvf gcc-$(VERSION).tar.bz2;
	cd ./gcc-$(VERSION) && \
		contrib/download_prerequisites && \
	cd .. && \
	mkdir -p gcc-build && cd gcc-build && \
		../gcc-$(VERSION)/configure \
			--prefix=$(PREFIX) \
			--enable-host-shared \
			--disable-multilib \
			--enable-threads \
			--enable-tls \
			--enable-bootstrap \
			--enable-gold=yes \
			--enable-ld=yes \
			--enable-compressed-debug-sections=all \
			--enable-libada \
			--enable-libssp \
			--enable-lto \
			--enable-objc-gc \
			--enable-vtable-verify \
			--enable-generated-files-in-srcdir \
			--enable-targets=all \
		&& \
		make -j$$(nproc);

#-------------------------------------------------------------------------------

.PHONY: install-tmp
install-tmp:
	mkdir -p /tmp/installdir-$(NAME)-$(VERSION);
	cd ./gcc-build && \
		make install DESTDIR=/tmp/installdir-$(NAME)-$(VERSION);

#-------------------------------------------------------------------------------

.PHONY: package
package:

	# Main package
	fpm \
		-f \
		-d "$(NAME)-libs = $(VERSION)-$(ITERATION).$(EL)$(RHEL)" \
		-s dir \
		-t rpm \
		-n $(NAME) \
		-v $(VERSION) \
		-C /tmp/installdir-$(NAME)-$(VERSION) \
		-m $(MAINTAINER) \
		--iteration $(ITERATION) \
		--license $(LICENSE) \
		--vendor $(VENDOR) \
		--prefix / \
		--url $(URL) \
		--description $(DESCRIPTION) \
		--rpm-defattrdir 0755 \
		--rpm-digest md5 \
		--rpm-compression gzip \
		--rpm-os linux \
		--rpm-changelog CHANGELOG-$(NAME).txt \
		--rpm-dist $(EL)$(RHEL) \
		--rpm-auto-add-directories \
		usr/local/bin \
	;

	# Libs package
	fpm \
		-f \
		-s dir \
		-t rpm \
		-n $(NAME)-libs \
		-v $(VERSION) \
		-C /tmp/installdir-$(NAME)-$(VERSION) \
		-m $(MAINTAINER) \
		--iteration $(ITERATION) \
		--license $(LICENSE) \
		--vendor $(VENDOR) \
		--prefix / \
		--url $(URL) \
		--description $(DESCRIPTION) \
		--rpm-defattrdir 0755 \
		--rpm-digest md5 \
		--rpm-compression gzip \
		--rpm-os linux \
		--rpm-changelog CHANGELOG-$(NAME).txt \
		--rpm-dist $(EL)$(RHEL) \
		--rpm-auto-add-directories \
		usr/local/lib \
		usr/local/lib64 \
		usr/local/libexec \
	;

	# Development package
	fpm \
		-f \
		-d "$(NAME) = $(VERSION)-$(ITERATION).$(EL)$(RHEL)" \
		-s dir \
		-t rpm \
		-n $(NAME)-devel \
		-v $(VERSION) \
		-C /tmp/installdir-$(NAME)-$(VERSION) \
		-m $(MAINTAINER) \
		--iteration $(ITERATION) \
		--license $(LICENSE) \
		--vendor $(VENDOR) \
		--prefix / \
		--url $(URL) \
		--description $(DESCRIPTION) \
		--rpm-defattrdir 0755 \
		--rpm-digest md5 \
		--rpm-compression gzip \
		--rpm-os linux \
		--rpm-changelog CHANGELOG-$(NAME).txt \
		--rpm-dist $(EL)$(RHEL) \
		--rpm-auto-add-directories \
		usr/local/include \
	;

	# Documentation package
	fpm \
		-f \
		-d "$(NAME) = $(VERSION)-$(ITERATION).$(EL)$(RHEL)" \
		-s dir \
		-t rpm \
		-n $(NAME)-doc \
		-v $(VERSION) \
		-C /tmp/installdir-$(NAME)-$(VERSION) \
		-m $(MAINTAINER) \
		--iteration $(ITERATION) \
		--license $(LICENSE) \
		--vendor $(VENDOR) \
		--prefix / \
		--url $(URL) \
		--description $(DESCRIPTION) \
		--rpm-defattrdir 0755 \
		--rpm-digest md5 \
		--rpm-compression gzip \
		--rpm-os linux \
		--rpm-changelog CHANGELOG-$(NAME).txt \
		--rpm-dist $(EL)$(RHEL) \
		--rpm-auto-add-directories \
		usr/local/share \
	;

#-------------------------------------------------------------------------------

.PHONY: move
move:
	[[ -d /vagrant/repo ]] && mv *.rpm /vagrant/repo/
