#
# CDDL HEADER START
#
# The contents of this file are subject to the terms of the
# Common Development and Distribution License (the "License").
# You may not use this file except in compliance with the License.
#
# You can obtain a copy of the license at usr/src/OPENSOLARIS.LICENSE
# or http://www.opensolaris.org/os/licensing.
# See the License for the specific language governing permissions
# and limitations under the License.
#
# When distributing Covered Code, include this CDDL HEADER in each
# file and include the License file at usr/src/OPENSOLARIS.LICENSE.
# If applicable, add the following below this CDDL HEADER, with the
# fields enclosed by brackets "[]" replaced with your own identifying
# information: Portions Copyright [yyyy] [name of copyright owner]
#
# CDDL HEADER END
#
# Copyright (c) 2010, 2016, Oracle and/or its affiliates. All rights reserved.
#

PATH=/usr/bin:/usr/gnu/bin

# The location of an internal mirror of community source archives that we build
# in this gate.  This mirror has been seeded to include "custom" source archives
# for a few components where the communities either no longer provide matching
# source archives or we have changes that aren't reflected in their archives or
# anywhere else.
INTERNAL_ARCHIVE_MIRROR =	http://userland.us.oracle.com/source-archives

# The location of an external mirror of community source archives that we build
# in this gate.  The external mirror is a replica of the internal mirror.
EXTERNAL_ARCHIVE_MIRROR = 

# Default to looking for source archives on the internal mirror and the external
# mirror before we hammer on the community source archive repositories.
export DOWNLOAD_SEARCH_PATH +=	$(INTERNAL_ARCHIVE_MIRROR)
ifneq   ($(strip $(EXTERNAL_ARCHIVE_MIRROR)),)
export DOWNLOAD_SEARCH_PATH +=	$(EXTERNAL_ARCHIVE_MIRROR)
endif

# The workspace starts at the parent of the make-rules directory,
# unless someone already supplied the top.
ifeq ($(origin WS_TOP), undefined)
export WS_TOP := $(realpath $(dir $(realpath $(dir $(filter \
			%/make-rules/shared-macros.mk,$(MAKEFILE_LIST))))))
endif

WS_MACH =	$(WS_TOP)/$(MACH)
WS_LOGS =	$(WS_MACH)/logs
WS_REPO =	$(WS_MACH)/repo
WS_TOOLS =	$(WS_TOP)/tools
WS_MAKE_RULES =	$(WS_TOP)/make-rules
WS_COMPONENTS =	$(WS_TOP)/components
WS_LICENSES =	$(WS_TOP)/licenses
WS_INCORPORATIONS =	$(WS_TOP)/incorporations
WS_LINT_CACHE =	$(WS_MACH)/pkglint-cache

# we want our pkg piplines to fail if there is an error
# (like if pkgdepend fails in the middle of a pipe), but
# we don't want the builds or ./configure's failing as well.
# so we only set pipefail for the publish target and have
# to reset it for the others since they might be invoked
# as dependencies of publish.
export SHELLOPTS
build:		SHELLOPTS=
test:		SHELLOPTS=
install:	SHELLOPTS=
publish:	SHELLOPTS=pipefail

# This can be overridden to avoid rebuilding when you touch a Makefile
MAKEFILE_PREREQ =	Makefile

# some things don't build properly in non-C locales,
# so lets stay there
export LC_ALL=C

SHELL=	/bin/bash

# We want "nightly" as our publisher, to match other consolidations and
# facilitate migrations.  G11N wants $(CONSOLIDATION)-localizable for
# the localizable publisher.
CONSOLIDATION =	userland
PUBLISHER ?=	nightly
PUBLISHER_LOCALIZABLE ?=	$(CONSOLIDATION)-localizable

# Defines $(space) as a single blank space, so we can use it to convert
# space-separated paths to colon-separated paths in variables with
# $(subst $(space),:,$(strip $(SPATHS)))
empty :=
space := $(empty) $(empty)

ROOT =			/

# The changset and external source repo used in building the packages.
CONSOLIDATION_CHANGESET=$(shell hg identify -i)
CONSOLIDATION_REPOSITORY_URL=https://hg.java.net/hg/solaris-userland~gate

# Native OS version
OS_VERSION :=		$(shell uname -r)
SOLARIS_VERSION =	$(OS_VERSION:5.%=2.%)
# Target OS version
PKG_SOLARIS_VERSION ?= 5.12

# We generally build the default branch on the latest release.  But for
# the FOSS evaluation repo project, we build on the previous release.
# Add macros to make that easier.
ifeq ($(OS_VERSION),5.12)
SOLARIS_12_ONLY =
SOLARIS_11_ONLY =\#
else
SOLARIS_12_ONLY =\#
SOLARIS_11_ONLY =
endif

include $(WS_MAKE_RULES)/ips-buildinfo.mk

COMPILER ?=		studio
BITS ?=			32

# The values of BITS changes during the build process for components that
# are built 32-bit and 64-bit.  This macro makes it possible to determine
# which components are only built 64-bit and allow other make-rules files
# to adjust accordingly.
INITIAL_BITS=		$(BITS)

# The default version should go last.
PYTHON_VERSION =	2.7
PYTHON2_VERSIONS =	2.7
PYTHON3_VERSIONS =	3.4 3.5
PYTHON_VERSIONS =	$(PYTHON3_VERSIONS) $(PYTHON2_VERSIONS)

BASS_O_MATIC =	$(WS_TOOLS)/bass-o-matic

CLONEY =	$(WS_TOOLS)/cloney

CONFIG_SHELL =	/bin/bash

PKG_REPO =	file:$(WS_REPO)

COMPONENT_SRC_NAME =	$(COMPONENT_NAME)

COMPONENT_DIR :=	$(shell pwd)
SOURCE_DIR =	$(COMPONENT_DIR)/$(COMPONENT_SRC)
BUILD_DIR =	$(COMPONENT_DIR)/build
PROTO_DIR =	$(BUILD_DIR)/prototype/$(MACH)

ETCDIR =	/etc
USRDIR =	/usr
BINDIR =	/bin
SBINDIR =	/sbin
LIBDIR =	/lib
VARDIR =	/var
USRBINDIR =	$(USRDIR)/bin
USRBINDIR64 =	$(USRDIR)/bin/$(MACH64)
USRSBINDIR =	$(USRDIR)/sbin
USRLIBDIR =	$(USRDIR)/lib
USRSHAREDIR =	$(USRDIR)/share
USRINCDIR =	$(USRDIR)/include
USRSHARELOCALEDIR =	$(USRSHAREDIR)/locale
USRSHAREMANDIR =	$(USRSHAREDIR)/man
USRSHAREDOCDIR =	$(USRSHAREDIR)/doc
USRSHAREFONTSDIR =	$(USRSHAREDIR)/fonts
USRSHARETTFONTSDIR =	$(USRSHAREFONTSDIR)/TrueType
USRSHARELIBDIR =	$(USRSHAREDIR)/lib
USRSHAREMAN1DIR =	$(USRSHAREMANDIR)/man1
USRSHAREMAN1MDIR =	$(USRSHAREMANDIR)/man1m
USRSHAREMAN3DIR =	$(USRSHAREMANDIR)/man3
USRSHAREMAN4DIR =	$(USRSHAREMANDIR)/man4
USRSHAREMAN5DIR =	$(USRSHAREMANDIR)/man5
USRLIBDIR64 =	$(USRDIR)/lib/$(MACH64)
PROTOBINDIR =	$(PROTO_DIR)/$(BINDIR)
PROTOETCDIR =	$(PROTO_DIR)/$(ETCDIR)
PROTOETCSECDIR = $(PROTO_DIR)/$(ETCDIR)/security
PROTOUSRDIR =	$(PROTO_DIR)/$(USRDIR)
PROTOLIBDIR =	$(PROTO_DIR)/$(LIBDIR)
PROTOSVCMANIFESTDIR =	$(PROTOLIBDIR)/svc/manifest
PROTOSVCMETHODDIR =	$(PROTOLIBDIR)/svc/method
PROTOUSRBINDIR =	$(PROTO_DIR)/$(USRBINDIR)
PROTOUSRBINDIR64 =	$(PROTO_DIR)/$(USRBINDIR64)
PROTOUSRSBINDIR =	$(PROTO_DIR)/$(USRSBINDIR)
PROTOUSRLIBDIR =	$(PROTO_DIR)/$(USRLIBDIR)
PROTOUSRLIBDIR64 =	$(PROTO_DIR)/$(USRLIBDIR64)
PROTOPKGCONFIGDIR = 	$(PROTOUSRLIBDIR)/pkgconfig
PROTOPKGCONFIGDIR64 =	$(PROTOUSRLIBDIR64)/pkgconfig
PROTOUSRINCDIR =	$(PROTO_DIR)/$(USRINCDIR)
PROTOUSRSHAREDIR =	$(PROTO_DIR)/$(USRSHAREDIR)
PROTOUSRSHARELIBDIR =	$(PROTO_DIR)/$(USRSHARELIBDIR)
PROTOUSRSHAREDOCDIR =	$(PROTO_DIR)/$(USRSHAREDOCDIR)
PROTOUSRSHAREINFODIR =	$(PROTOUSRSHAREDIR)/info
PROTOUSRSHAREMANDIR =	$(PROTO_DIR)/$(USRSHAREMANDIR)
PROTOUSRSHAREMAN1DIR =	$(PROTO_DIR)/$(USRSHAREMAN1DIR)
PROTOUSRSHAREMAN1MDIR =	$(PROTO_DIR)/$(USRSHAREMAN1MDIR)
PROTOUSRSHAREMAN3DIR =	$(PROTO_DIR)/$(USRSHAREMAN3DIR)
PROTOUSRSHAREMAN4DIR =	$(PROTO_DIR)/$(USRSHAREMAN4DIR)
PROTOUSRSHAREMAN5DIR =	$(PROTO_DIR)/$(USRSHAREMAN5DIR)
PROTOUSRSHARELOCALEDIR =	$(PROTO_DIR)/$(USRSHARELOCALEDIR)


SFWBIN =	/usr/sfw/bin
SFWINCLUDE =	/usr/sfw/include
SFWLIB =	/usr/sfw/lib
SFWLIB64 =	/usr/sfw/lib/$(MACH64)
SFWSHARE =	/usr/sfw/share
SFWSHAREMAN =	/usr/sfw/share/man
SFWSHAREMAN1 =	/usr/sfw/share/man/man1
PROTOSFWBIN =	$(PROTO_DIR)/$(SFWBIN)
PROTOSFWLIB =	$(PROTO_DIR)/$(SFWLIB)
PROTOSFWLIB64 =	$(PROTO_DIR)/$(SFWLIB64)
PROTOSFWSHARE =	$(PROTO_DIR)/$(SFWSHARE)
PROTOSFWSHAREMAN =	$(PROTO_DIR)/$(SFWSHAREMAN)
PROTOSFWSHAREMAN1 =	$(PROTO_DIR)/$(SFWSHAREMAN1)
PROTOSFWINCLUDE =	$(PROTO_DIR)/$(SFWINCLUDE)

GNUBIN =	/usr/gnu/bin
GNULIB =	/usr/gnu/lib
GNULIB64 =	/usr/gnu/lib/$(MACH64)
GNUSHARE =	/usr/gnu/share
GNUSHAREMAN =	/usr/gnu/share/man
GNUSHAREMAN1 =	/usr/gnu/share/man/man1
PROTOGNUBIN =	$(PROTO_DIR)/$(GNUBIN)
PROTOGNUSHARE =	$(PROTO_DIR)/$(GNUSHARE)
PROTOGNUSHAREMAN =	$(PROTO_DIR)/$(GNUSHAREMAN)
PROTOGNUSHAREMAN1 =	$(PROTO_DIR)/$(GNUSHAREMAN1)

# work around _TIME, _DATE, embedded date chatter in component builds
# to use, set TIME_CONSTANT in the component Makefile and add $(CONSTANT_TIME)
# to the appropriate {CONFIGURE|BUILD|INSTALL}_ENV
CONSTANT_TIME =		LD_PRELOAD_32=$(WS_TOOLS)/time-$(MACH32).so
CONSTANT_TIME +=	LD_PRELOAD_64=$(WS_TOOLS)/time-$(MACH64).so
CONSTANT_TIME +=	TIME_CONSTANT=$(TIME_CONSTANT)

# set MACH from uname -p to either sparc or i386
MACH :=		$(shell uname -p)

# set MACH32 from MACH to either sparcv7 or i86
MACH32_1 =	$(MACH:sparc=sparcv7)
MACH32 =	$(MACH32_1:i386=i86)

# set MACH64 from MACH to either sparcv9 or amd64
MACH64_1 =	$(MACH:sparc=sparcv9)
MACH64 =	$(MACH64_1:i386=amd64)

CONFIGURE_NO_ARCH =	$(BUILD_DIR_NO_ARCH)/.configured
CONFIGURE_32 =		$(BUILD_DIR_32)/.configured
CONFIGURE_64 =		$(BUILD_DIR_64)/.configured
CONFIGURE_32_and_64 =	$(CONFIGURE_32) $(CONFIGURE_64)

BUILD_DIR_NO_ARCH =	$(BUILD_DIR)/$(MACH)
BUILD_DIR_32 =		$(BUILD_DIR)/$(MACH32)
BUILD_DIR_64 =		$(BUILD_DIR)/$(MACH64)

BUILD_NO_ARCH =		$(BUILD_DIR_NO_ARCH)/.built
BUILD_32 =		$(BUILD_DIR_32)/.built
BUILD_64 =		$(BUILD_DIR_64)/.built
BUILD_32_and_64 =	$(BUILD_32) $(BUILD_64)
# NO_ARCH uses BITS=32 because some path setting macros use $(BITS)
$(BUILD_DIR_NO_ARCH)/.built:	BITS=32
$(BUILD_DIR_32)/.built:		BITS=32
$(BUILD_DIR_64)/.built:		BITS=64

INSTALL_NO_ARCH =	$(BUILD_DIR_NO_ARCH)/.installed
INSTALL_32 =		$(BUILD_DIR_32)/.installed
INSTALL_64 =		$(BUILD_DIR_64)/.installed
INSTALL_32_and_64 =	$(INSTALL_32) $(INSTALL_64)
$(BUILD_DIR_NO_ARCH)/.installed:  BITS=32
$(BUILD_DIR_32)/.installed:       BITS=32
$(BUILD_DIR_64)/.installed:       BITS=64

# set the default target for installation of the component
COMPONENT_INSTALL_TARGETS =	install

# set the default build test results directory
COMPONENT_TEST_BUILD_DIR =	$(BUILD_DIR)/test/$(MACH$(BITS))

# set the default master test results directory
COMPONENT_TEST_RESULTS_DIR =	$(COMPONENT_DIR)/test
COMPONENT_SYSTEM_TEST_RESULTS_DIR =	$(COMPONENT_DIR)/test

# set the default master test results file
COMPONENT_TEST_MASTER =		$(COMPONENT_TEST_RESULTS_DIR)/results-$(BITS).master

# set the default test results output file
COMPONENT_TEST_OUTPUT =		$(COMPONENT_TEST_BUILD_DIR)/test-$(BITS)-results

# set the default test results comparison diffs file
COMPONENT_TEST_DIFFS =		$(COMPONENT_TEST_BUILD_DIR)/test-$(BITS)-diffs

# set the default test snapshot file
COMPONENT_TEST_SNAPSHOT =	$(COMPONENT_TEST_BUILD_DIR)/results-$(BITS).snapshot

# Normally $(GSED) is simplest, but some results files need more power.
COMPONENT_TEST_TRANSFORMER =	$(GSED)

# The set of default transforms to be applied to the test results to try
# to normalize them.
COMPONENT_TEST_TRANSFORMS = \
	'-e "s|$(@D)|\\$$(@D)|g" ' \
	'-e "s|$(PERL)|\\$$(PERL)|g" ' \
	'-e "s|$(SOURCE_DIR)|\\$$(SOURCE_DIR)|g" '

# set the default commands used to generate the file containing the set
# of transforms to be applied to the test results to try to normalize them.
COMPONENT_TEST_CREATE_TRANSFORMS = \
	@if [ -e $(COMPONENT_TEST_MASTER) ]; \
	then \
		print "\#!/bin/sh" > $(COMPONENT_TEST_TRANSFORM_CMD); \
        	print '$(COMPONENT_TEST_TRANSFORMER) ' \
			$(COMPONENT_TEST_TRANSFORMS) \
                	' \\' >> $(COMPONENT_TEST_TRANSFORM_CMD); \
        	print '$(COMPONENT_TEST_OUTPUT) \\' \
                	>> $(COMPONENT_TEST_TRANSFORM_CMD); \
        	print '> $(COMPONENT_TEST_SNAPSHOT)' \
                	>> $(COMPONENT_TEST_TRANSFORM_CMD); \
	else \
		print 'Cannot find $(COMPONENT_TEST_MASTER)'; \
		exit 2; \
	fi

# set the default command for performing any test result munging
COMPONENT_TEST_TRANSFORM_CMD =	$(COMPONENT_TEST_BUILD_DIR)/transform-$(BITS)-results

# set the default operation to run to perform test result normalization
COMPONENT_TEST_PERFORM_TRANSFORM = \
	@if [ -e $(COMPONENT_TEST_MASTER) ]; \
	then \
		$(SHELL) $(COMPONENT_TEST_TRANSFORM_CMD); \
	else \
		print 'Cannot find $(COMPONENT_TEST_MASTER)'; \
		exit 2; \
	fi

# set the default command used to compare the master results with the snapshot
COMPONENT_TEST_COMPARE_CMD =	$(GDIFF) -uN

# set the default way that master and snapshot test results are compared
COMPONENT_TEST_COMPARE = \
	@if [ -e $(COMPONENT_TEST_MASTER) ]; \
	then \
		$(COMPONENT_TEST_COMPARE_CMD) \
			$(COMPONENT_TEST_MASTER) $(COMPONENT_TEST_SNAPSHOT) \
			> $(COMPONENT_TEST_DIFFS); \
		print "Test results in $(COMPONENT_TEST_OUTPUT)"; \
		if [ -s $(COMPONENT_TEST_DIFFS) ]; \
		then \
			print "Differences found."; \
			$(CAT) $(COMPONENT_TEST_DIFFS); \
			exit 2; \
		else \
			print "No differences found."; \
		fi \
	else \
		print 'Cannot find $(COMPONENT_TEST_MASTER)'; \
		exit 2; \
	fi

# set the default env command to use for test of the component
COMPONENT_TEST_ENV_CMD =        $(ENV)
COMPONENT_SYSTEM_TEST_ENV_CMD =	$(ENV)

# set the default command to use for test of the component
COMPONENT_TEST_CMD =		$(GMAKE)
COMPONENT_SYSTEM_TEST_CMD =	$(GMAKE)

# set the default target for test of the component
COMPONENT_TEST_TARGETS =	check
COMPONENT_SYSTEM_TEST_TARGETS =	check

# set the default directory for test of the component
COMPONENT_TEST_DIR =		$(@D)
COMPONENT_SYSTEM_TEST_DIR =	$(@D)

# determine the type of tests we want to run.
ifeq ($(strip $(wildcard $(COMPONENT_SYSTEM_TEST_RESULTS_DIR)/results-*.master)),)
SYSTEM_TEST_NO_ARCH =		$(BUILD_DIR_NO_ARCH)/.system-tested
SYSTEM_TEST_32 =		$(BUILD_DIR_32)/.system-tested
SYSTEM_TEST_64 =		$(BUILD_DIR_64)/.system-tested
else
SYSTEM_TEST_NO_ARCH =		$(BUILD_DIR_NO_ARCH)/.system-tested-and-compared
SYSTEM_TEST_32 =		$(BUILD_DIR_32)/.system-tested-and-compared
SYSTEM_TEST_64 =		$(BUILD_DIR_64)/.system-tested-and-compared
endif
SYSTEM_TEST_32_and_64 =	$(SYSTEM_TEST_32) $(SYSTEM_TEST_64)
ifeq ($(strip $(wildcard $(COMPONENT_TEST_RESULTS_DIR)/results-*.master)),)
TEST_NO_ARCH =		$(BUILD_DIR_NO_ARCH)/.tested
TEST_32 =		$(BUILD_DIR_32)/.tested
TEST_64 =		$(BUILD_DIR_64)/.tested
else
TEST_NO_ARCH =		$(BUILD_DIR_NO_ARCH)/.tested-and-compared
TEST_32 =		$(BUILD_DIR_32)/.tested-and-compared
TEST_64 =		$(BUILD_DIR_64)/.tested-and-compared
endif
TEST_32_and_64 =	$(TEST_32) $(TEST_64)

# When running tests at the top level, skip those tests,
# by redefining the above TEST_* targets,
# when a component Makefile includes $(SKIP_TEST_AT_TOP_LEVEL).
# It's done in separate skip-test.mk file, to allow inclusion of 
# a multi-line ifdef statement which is evaluated at the component
# Makefile level

SKIP_TEST_AT_TOP_LEVEL = $(eval include $(WS_MAKE_RULES)/skip-test.mk)

$(BUILD_DIR_NO_ARCH)/.system-tested:			BITS=32
$(BUILD_DIR_32)/.system-tested:				BITS=32
$(BUILD_DIR_64)/.system-tested:				BITS=64
$(BUILD_DIR_NO_ARCH)/.system-tested-and-compared:	BITS=32
$(BUILD_DIR_32)/.system-tested-and-compared:		BITS=32
$(BUILD_DIR_64)/.system-tested-and-compared:		BITS=64
$(BUILD_DIR_NO_ARCH)/.tested:				BITS=32
$(BUILD_DIR_32)/.tested:				BITS=32
$(BUILD_DIR_64)/.tested:				BITS=64
$(BUILD_DIR_NO_ARCH)/.tested-and-compared:		BITS=32
$(BUILD_DIR_32)/.tested-and-compared:			BITS=32
$(BUILD_DIR_64)/.tested-and-compared:			BITS=64

$(BUILD_DIR_NO_ARCH)/.system-tested:			$(BUILD_DIR_32)
$(BUILD_DIR_32)/.system-tested:				$(BUILD_DIR_32)
$(BUILD_DIR_64)/.system-tested:				$(BUILD_DIR_64)
$(BUILD_DIR_NO_ARCH)/.system-tested-and-compared:	$(BUILD_DIR_32)
$(BUILD_DIR_32)/.system-tested-and-compared:		$(BUILD_DIR_32)
$(BUILD_DIR_64)/.system-tested-and-compared:		$(BUILD_DIR_64)

$(BUILD_DIR_32) $(BUILD_DIR_64):
	$(MKDIR) $(@)

# BUILD_TOOLS is the root of all tools not normally installed on the system.
BUILD_TOOLS ?=	/ws/on12-tools

SPRO_ROOT =	$(BUILD_TOOLS)/SUNWspro
SPRO_VROOT =	$(SPRO_ROOT)/solarisstudio12.4

PARFAIT_ROOT =	$(BUILD_TOOLS)/parfait/parfait-tools-1.7.1
PARFAIT_TOOLS=	$(WS_TOOLS)/$(MACH)/parfait
PARFAIT_TOOLS_GCC3=	$(PARFAIT_TOOLS)/gcc3
PARFAIT= $(PARFAIT_ROOT)/bin/parfait
export PARFAIT_NATIVESUNCC=$(SPRO_VROOT)/bin/cc
export PARFAIT_NATIVESUNCXX=$(SPRO_VROOT)/bin/CC
export PARFAIT_NATIVEGCC=$(GCC_ROOT)/bin/gcc
export PARFAIT_NATIVEGXX=$(GCC_ROOT)/bin/g++

GCC_ROOT =	/usr/gcc/4.8
GCC3_ROOT =	/usr/gcc/3.4

CC.studio.32 =	$(SPRO_VROOT)/bin/cc
CXX.studio.32 =	$(SPRO_VROOT)/bin/CC


CC.studio.64 =	$(SPRO_VROOT)/bin/cc
CXX.studio.64 =	$(SPRO_VROOT)/bin/CC

CC.gcc.32 =	$(GCC_ROOT)/bin/gcc
CXX.gcc.32 =	$(GCC_ROOT)/bin/g++

CC.gcc.64 =	$(GCC_ROOT)/bin/gcc
CXX.gcc.64 =	$(GCC_ROOT)/bin/g++

CC.gcc3.32 =	$(GCC3_ROOT)/bin/gcc
CXX.gcc3.32 =	$(GCC3_ROOT)/bin/g++

CC.gcc3.64 =	$(GCC3_ROOT)/bin/gcc
CXX.gcc3.64 =	$(GCC3_ROOT)/bin/g++

lint.32 =	$(SPRO_VROOT)/bin/lint -m32
lint.64 =	$(SPRO_VROOT)/bin/lint -m64

LINT =		$(lint.$(BITS))

LD =		/usr/bin/ld

ifeq   ($(strip $(PARFAIT_BUILD)),yes)
CC.studio.32 =	$(PARFAIT_TOOLS)/cc
CXX.studio.32 =	$(PARFAIT_TOOLS)/CC
CC.studio.64 =	$(PARFAIT_TOOLS)/cc
CXX.studio.64 =	$(PARFAIT_TOOLS)/CC
CC.gcc.32 =	$(PARFAIT_TOOLS)/gcc
CXX.gcc.32 =	$(PARFAIT_TOOLS)/g++
CC.gcc.64 =	$(PARFAIT_TOOLS)/gcc
CXX.gcc.64 =	$(PARFAIT_TOOLS)/g++
CC.gcc3.32 =	$(PARFAIT_TOOLS_GCC3)/gcc
CXX.gcc3.32 =	$(PARFAIT_TOOLS_GCC3)/g++
CC.gcc3.64 =	$(PARFAIT_TOOLS_GCC3)/gcc
CXX.gcc3.64 =	$(PARFAIT_TOOLS_GCC3)/g++
LD =		$(PARFAIT_TOOLS)/ld
endif

CC =		$(CC.$(COMPILER).$(BITS))
CXX =		$(CXX.$(COMPILER).$(BITS))

RUBY_VERSION =	2.1
RUBY_LIB_VERSION =	2.1.0
RUBY.2.1 =	/usr/ruby/2.1/bin/ruby
RUBY =		$(RUBY.$(RUBY_VERSION))
# Use the ruby lib versions to represent the RUBY_VERSIONS that
# need to get built.  This is done because during package transformations
# both the ruby version and the ruby library version are needed. 
RUBY_VERSIONS = $(RUBY_LIB_VERSION)

PYTHON.2.7.VENDOR_PACKAGES.32 = /usr/lib/python2.7/vendor-packages
PYTHON.2.7.VENDOR_PACKAGES.64 = /usr/lib/python2.7/vendor-packages/64
PYTHON.2.7.VENDOR_PACKAGES = $(PYTHON.2.7.VENDOR_PACKAGES.$(BITS))

PYTHON.3.4.VENDOR_PACKAGES.64 = /usr/lib/python3.4/vendor-packages/64
PYTHON.3.4.VENDOR_PACKAGES = $(PYTHON.3.4.VENDOR_PACKAGES.$(BITS))

PYTHON.3.5.VENDOR_PACKAGES.64 = /usr/lib/python3.5/vendor-packages
PYTHON.3.5.VENDOR_PACKAGES = $(PYTHON.3.5.VENDOR_PACKAGES.$(BITS))

PYTHON_VENDOR_PACKAGES.32 = /usr/lib/python$(PYTHON_VERSION)/vendor-packages
PYTHON_VENDOR_PACKAGES.64 = /usr/lib/python$(PYTHON_VERSION)/vendor-packages/64
PYTHON_VENDOR_PACKAGES = $(PYTHON_VENDOR_PACKAGES.$(BITS))

PYTHON.2.7.TEST = /usr/lib/python2.7/test
PYTHON.3.4.TEST = /usr/lib/python3.4/test
PYTHON.3.5.TEST = /usr/lib/python3.5/test

USRBIN.32 =	/usr/bin
USRBIN.64 =	/usr/bin/$(MACH64)
USRBIN =	$(USRBIN.$(BITS))

USRLIB.32 =	$(USRLIBDIR)
USRLIB.64 =	$(USRLIBDIR64)
USRLIB =	$(USRLIB.$(BITS))

PYTHON.2.7.32 =	$(USRBIN.32)/python2.7
PYTHON.2.7.64 =	$(USRBIN.64)/python2.7
PYTHON.2.7 =	$(USRBIN)/python2.7

# Although we build Python 3 64-bit only, the BUILD_NO_ARCH macro is written
# in such a way that we still need the .32 macro below.  And since we build
# 64-bit only, we stick it directly in usr/bin (i.e., the 32-bit path) rather
# than the 64-bit path.
PYTHON.3.4.32 =	$(USRBIN.32)/python3.4
PYTHON.3.4.64 =	$(USRBIN.32)/python3.4
PYTHON.3.4 =	$(USRBIN.32)/python3.4

PYTHON.3.5.32 =	$(USRBIN.32)/python3.5
PYTHON.3.5.64 =	$(USRBIN.32)/python3.5
PYTHON.3.5 =	$(USRBIN.32)/python3.5

PYTHON.32 =	$(PYTHON.$(PYTHON_VERSION).32)
PYTHON.64 =	$(PYTHON.$(PYTHON_VERSION).64)
PYTHON =	$(PYTHON.$(PYTHON_VERSION).$(BITS))

# The default is site-packages, but that directory belongs to the end-user.
# Modules which are shipped by the OS but not with the core Python distribution
# belong in vendor-packages.
PYTHON_LIB= /usr/lib/python$(PYTHON_VERSION)/vendor-packages
PYTHON_DATA= $(PYTHON_LIB)

JAVA8_HOME =	/usr/jdk/instances/jdk1.8.0
JAVA7_HOME =	/usr/jdk/instances/jdk1.7.0
JAVA_HOME = $(JAVA8_HOME)

# This is the default BUILD version of perl
# Not necessarily the system's default version, i.e. /usr/bin/perl
PERL_VERSION ?=  5.12

PERL_VERSIONS = 5.12 5.20

PERL.5.12 =     /usr/perl5/5.12/bin/perl
PERL.5.16 =	/usr/perl5/5.16/bin/perl
PERL.5.12-mt =	/usr/perl5/5.12/bin/perl-threaded
PERL.5.20 =     /usr/perl5/5.20/bin/perl

PERL =          $(PERL.$(PERL_VERSION))
PERL_PKG =	$(PERL_VERSION:5.%=runtime/perl-5%)

PERL_ARCH :=	$(shell $(PERL) -e 'use Config; print $$Config{archname}')
PERL_ARCH_FUNC=	$(shell $(1) -e 'use Config; print $$Config{archname}')
# Optimally we should ask perl which C compiler was used but it doesn't
# result in a full path name.  Only "c" is being recorded
# inside perl builds while we actually need a full path to
# the studio compiler.
#PERL_CC :=	$(shell $(PERL) -e 'use Config; print $$Config{cc}')
PERL_OPTIMIZE :=$(shell $(PERL) -e 'use Config; print $$Config{optimize}')

PKG_MACROS +=   PERL_ARCH=$(PERL_ARCH)
PKG_MACROS +=   PERL_VERSION=$(PERL_VERSION)

# This is the default BUILD version of tcl
# Not necessarily the system's default version, i.e. /usr/bin/tclsh
TCL_VERSION =  8.5
TCLSH.8.5.i386.32 =	/usr/bin/i86/tclsh8.5
TCLSH.8.5.i386.64 =	/usr/bin/amd64/tclsh8.5
TCLSH.8.5.sparc.32 =	/usr/bin/sparcv7/tclsh8.5
TCLSH.8.5.sparc.64 =	/usr/bin/sparcv9/tclsh8.5
TCLSH =		$(TCLSH.$(TCL_VERSION).$(MACH).$(BITS))

CCSMAKE =	/usr/ccs/bin/make
GMAKE =		/usr/gnu/bin/make
GPATCH =	/usr/gnu/bin/patch
PATCH_LEVEL =	1
GPATCH_BACKUP =	--backup --version-control=numbered
GPATCH_FLAGS =	-p$(PATCH_LEVEL) $(GPATCH_BACKUP)
GSED =		/usr/gnu/bin/sed
GDIFF =		/usr/gnu/bin/diff
GSORT =		/usr/gnu/bin/sort
GUNZIP =	/usr/bin/gunzip

PKGREPO =	/usr/bin/pkgrepo
PKGSEND =	/usr/bin/pkgsend
ifeq   ($(strip $(PKGLINT_COMPONENT)),)
PKGLINT =	/usr/bin/pkglint
else
PKGLINT =	${WS_TOOLS}/pkglint
endif

ACLOCAL =	/usr/bin/aclocal-1.10
AUTOMAKE =	/usr/bin/automake-1.10
AUTORECONF = 	/usr/bin/autoreconf

KSH93 =         /usr/bin/ksh93
TOUCH =		/usr/bin/touch
MKDIR =		/bin/mkdir -p
RM =		/bin/rm -f
CP =		/bin/cp -f
MV =		/bin/mv -f
LN =		/bin/ln
CAT =		/bin/cat
SYMLINK =	/bin/ln -s
ENV =		/usr/bin/env
INSTALL =	/usr/bin/ginstall
GNU_GREP =	/usr/gnu/bin/grep
CHMOD =		/usr/bin/chmod
NAWK =		/usr/bin/nawk
TEE =		/usr/bin/tee

INS.dir=        $(INSTALL) -d $@
INS.file=       $(INSTALL) -m 444 $< $(@D)

#
# To simplify adding directories to PKG_CONFIG_PATH, since += adds spaces, not :
# use PKG_CONFIG_PATHS += ... and the following will convert to the : form
#
PKG_CONFIG_PATH.32 = /usr/lib/pkgconfig
PKG_CONFIG_PATH.64 = /usr/lib/$(MACH64)/pkgconfig
PKG_CONFIG_DEFAULT = $(PKG_CONFIG_PATH.$(BITS))
PKG_CONFIG_PATH    = $(subst $(space),:,$(strip \
			$(PKG_CONFIG_PATHS) $(PKG_CONFIG_DEFAULT)))

#
# C preprocessor flag sets to ease feature selection.  Add the required
# feature to your Makefile with CPPFLAGS += $(FEATURE_MACRO) and add to
# the component build with CONFIGURE_OPTIONS += CPPFLAGS="$(CPPFLAGS)" or
# similiar.
#

# Enables visibility of some c99 math functions that aren't visible by default.
# What other side-effects are there?
CPP_C99_EXTENDED_MATH =	-D_STDC_99

# Enables large file support for components that have no other means of doing
# so.  Use CPP_LARGEFILES and not the .32/.64 variety directly
CPP_LARGEFILES.32 :=	$(shell getconf LFS_CFLAGS)
CPP_LARGEFILES.64 :=	$(shell getconf LFS64_CFLAGS)
CPP_LARGEFILES =		$(CPP_LARGEFILES.$(BITS))

# Enables some #pragma redefine_extname to POSIX-compliant Standard C Library
# functions. Also avoids the component's #define _POSIX_C_SOURCE to some value
# we currently do not support.
CPP_POSIX =	-D_POSIX_C_SOURCE=200112L -D_POSIX_PTHREAD_SEMANTICS

# XPG6 mode.  This option enables XPG6 conformance, plus extensions.
# Amongst other things, this option will cause system calls like
# popen (3C) and system (3C) to invoke the standards-conforming
# shell, /usr/xpg4/bin/sh, instead of /usr/bin/sh.  Add studio_XPG6MODE to
# CFLAGS instead of using this directly
CPP_XPG6MODE=	-D_XOPEN_SOURCE=600 -D__EXTENSIONS__=1 -D_XPG6

# XPG5 mode. These options are specific for C++, where _XPG6,
# _XOPEN_SOURCE=600 and C99 are illegal. -D__EXTENSIONS__=1 is legal in C++.
CPP_XPG5MODE=   -D_XOPEN_SOURCE=500 -D__EXTENSIONS__=1 -D_XPG5

#
# Studio C compiler flag sets to ease feature selection.  Add the required
# feature to your Makefile with CFLAGS += $(FEATURE_MACRO) and add to the
# component build with CONFIGURE_OPTIONS += CFLAGS="$(CFLAGS)" or similiar.
#

# Generate 32/64 bit objects
CC_BITS =	-m$(BITS)

# Code generation instruction set and optimization 'hints'.  Use studio_XBITS
# and not the .arch.bits variety directly.
studio_XBITS.sparc.32 =	-xtarget=ultra2 -xarch=sparcvis -xchip=ultra2
studio_XBITS.sparc.64 =	
ifneq   ($(strip $(PARFAIT_BUILD)),yes)
studio_XBITS.sparc.64 += -xtarget=ultra2
endif
studio_XBITS.sparc.64 += -xarch=sparcvis -xchip=ultra2
studio_XBITS.i386.32 =	-xchip=pentium
studio_XBITS.i386.64 =	-xchip=generic -Ui386 -U__i386
studio_XBITS = $(studio_XBITS.$(MACH).$(BITS))

# Turn on recognition of supported C99 language features and enable the 1999 C
# standard library semantics of routines that appear in	both the 1990 and
# 1999 C standard. To use set studio_C99MODE=$(studio_C99_ENABLE) in your
# component Makefile.
studio_C99_ENABLE =		-xc99=all

# Turn off recognition of C99 language features, and do not enable the 1999 C
# standard library semantics of routines that appeared in both the 1990	and
# 1999 C standard.  To use set studio_C99MODE=$(studio_C99_DISABLE) in your
# component Makefile.
studio_C99_DISABLE =	-xc99=none

# Use the compiler default 'xc99=all,no_lib'
studio_C99MODE =

# For C++, compatibility with C99 (which is technically illegal) is
# enabled in a different way. So, we must use a different macro for it.
studio_cplusplus_C99_ENABLE = 	-xlang=c99

# Turn it off.
studio_cplusplus_C99_DISABLE =

# And this is the macro you should actually use
studio_cplusplus_C99MODE = 

# Allow zero-sized struct/union declarations and void functions with return
# statements.
studio_FEATURES_EXTENSIONS =	-features=extensions

# Control the Studio optimization level.
studio_OPT.sparc.32 ?=	-xO4
studio_OPT.sparc.64 ?=	-xO4
studio_OPT.i386.32 ?=	-xO4
studio_OPT.i386.64 ?=	-xO4
studio_OPT ?=		$(studio_OPT.$(MACH).$(BITS))

# Studio PIC code generation.  Use CC_PIC instead to select PIC code generation.
studio_PIC = 	-KPIC -DPIC

# The Sun Studio 11 compiler has changed the behaviour of integer
# wrap arounds and so a flag is needed to use the legacy behaviour
# (without this flag panics/hangs could be exposed within the source).
# This is used through studio_IROPTS, not the 'sparc' variety.
studio_IROPTS.sparc =	-W2,-xwrap_int
studio_IROPTS =		$(studio_IROPTS.$(MACH))

# Control register usage for generated code.  SPARC ABI requires system
# libraries not to use application registers.  x86 requires 'no%frameptr' at
# x04 or higher.

# We should just use -xregs but we need to workaround 7030022. Note
# that we can't use the (documented) -Wc,-xregs workaround because
# libtool really hates -Wc and thinks it should be -Wl. Instead
# we use an (undocumented) option which actually happens to be what
# CC would use.
studio_XREGS.sparc =	-Qoption cg -xregs=no%appl
studio_XREGS.i386 =	-xregs=no%frameptr
studio_XREGS =		$(studio_XREGS.$(MACH))

gcc_XREGS.sparc =	-mno-app-regs
gcc_XREGS.i386 =
gcc_XREGS =		$(gcc_XREGS.$(MACH))

# Set data alignment on sparc to reasonable values, 8 byte alignment for 32 bit
# objects and 16 byte alignment for 64 bit objects.  This is added to CFLAGS by
# default.
studio_ALIGN.sparc.32 =	-xmemalign=8s
studio_ALIGN.sparc.64 =	-xmemalign=16s
studio_ALIGN =		$(studio_ALIGN.$(MACH).$(BITS))

# Studio shorthand for building multi-threaded code,  enables -D_REENTRANT and
# linking with threadin support.  This is added to CFLAGS by default, override
# studio_MT to turn this off.
studio_MT =		-mt

# See CPP_XPG6MODE comment above.
studio_XPG6MODE =	$(studio_C99MODE) $(CPP_XPG6MODE)
XPG6MODE =		$(studio_XPG6MODE)

# See CPP_XPG5MODE comment above. You can only use this in C++, not in C99.
studio_XPG5MODE =	$(studio_cplusplus_C99MODE) $(CPP_XPG5MODE)
XPG5MODE =		$(studio_XPG5MODE)

# Default Studio C compiler flags.  Add the required feature to your Makefile
# with CFLAGS += $(FEATURE_MACRO) and add to the component build with
# CONFIGURE_OPTIONS += CFLAGS="$(CFLAGS)" or similiar.  In most cases, it
# should not be necessary to add CFLAGS to any environment other than the
# configure environment.
CFLAGS.studio +=	$(studio_OPT) $(studio_XBITS) $(studio_XREGS) \
			$(studio_IROPTS) $(studio_C99MODE) $(studio_ALIGN) \
			$(studio_MT)

# Default Studio C++ compiler flags.  Add the required feature to your Makefile
# with CXXFLAGS += $(FEATURE_MACRO) and add to the component build with
# CONFIGURE_OPTIONS += CXXFLAGS="$(CXXFLAGS)" or similiar.  In most cases, it
# should not be necessary to add CXXFLAGS to any environment other than the
# configure environment.
CXXFLAGS.studio +=	$(studio_OPT) $(studio_XBITS) $(studio_XREGS) \
			$(studio_IROPTS) $(studio_ALIGN)

#
# GNU C compiler flag sets to ease feature selection.  Add the required
# feature to your Makefile with CFLAGS += $(FEATURE_MACRO) and add to the
# component build with CONFIGURE_OPTIONS += CFLAGS="$(CFLAGS)" or similiar.
#

# GCC Compiler optimization flag
gcc_OPT.sparc.32 ?=	-O3
gcc_OPT.sparc.64 ?=	-O3
gcc_OPT.i386.32 ?=	-O3
gcc_OPT.i386.64 ?=	-O3
gcc_OPT ?=		$(gcc_OPT.$(MACH).$(BITS))

# GCC PIC code generation.  Use CC_PIC instead to select PIC code generation.
gcc_PIC =	-fPIC -DPIC

# Generic macro for PIC code generation.  Use this macro instead of the
# compiler-specific variant.
CC_PIC =	$($(COMPILER)_PIC)


# Default GNU C compiler flags.  Add the required feature to your Makefile
# with CFLAGS += $(FEATURE_MACRO) and add to the component build with
# CONFIGURE_OPTIONS += CFLAGS="$(CFLAGS)" or similiar.  In most cases, it
# should not be necessary to add CFLAGS to any environment other than the
# configure environment.
CFLAGS.gcc +=	$(gcc_OPT)
CFLAGS.gcc +=	$(gcc_XREGS)
CFLAGS.gcc3 +=	$(gcc_OPT)
CFLAGS.gcc3 +=	$(gcc_XREGS)

# Default GNU C++ compiler flags.  Add the required feature to your Makefile
# with CXXFLAGS += $(FEATURE_MACRO) and add to the component build with
# CONFIGURE_OPTIONS += CXXFLAGS="$(CXXFLAGS)" or similiar.  In most cases, it
# should not be necessary to add CXXFLAGS to any environment other than the
# configure environment.
CXXFLAGS.gcc +=		$(gcc_OPT)
CXXFLAGS.gcc +=		$(gcc_XREGS)
CXXFLAGS.gcc3 +=	$(gcc_OPT)
CXXFLAGS.gcc3 +=	$(gcc_XREGS)

# Build 32 or 64 bit objects.
CFLAGS +=	$(CC_BITS)

# Add compiler-specific 'default' features
CFLAGS +=	$(CFLAGS.$(COMPILER))
CFLAGS +=	$(CFLAGS.$(COMPILER).$(BITS))

# Studio C++ requires -norunpath to avoid adding its location into the RUNPATH
# to C++ applications.
studio_NORUNPATH =	 -norunpath

# To link in standard mode (the default mode) without any C++ libraries
# (except libCrun), use studio_LIBRARY_NONE in your component Makefile.
studio_LIBRARY_NONE =	 -library=%none

# Don't link C++ with any C++ Runtime or Standard C++ library
studio_CXXLIB_NONE =	-xnolib

# Link C++ with the Studio C++ Runtime and Standard C++ library.  This is the
# default for "standard" mode.
studio_CXXLIB_CSTD =	-library=Cstd,Crun

# link C++ with the Studio  C++ Runtime and Apache Standard C++ library
studio_CXXLIB_APACHE =	-library=stdcxx4,Crun

# Add the C++ ABI compatibility flags for older ABI compatibility.  The default
# is "standard mode" (-compat=5)
studio_COMPAT_VERSION_4 =	-compat=4

# Tell the compiler that we don't want the studio runpath added to the
# linker flags.  We never want the Studio location added to the RUNPATH.
CXXFLAGS +=	$($(COMPILER)_NORUNPATH)

# Build 32 or 64 bit objects in C++ as well.
CXXFLAGS +=	$(CC_BITS)

# Add compiler-specific 'default' features
CXXFLAGS +=	$(CXXFLAGS.$(COMPILER))
CXXFLAGS +=	$(CXXFLAGS.$(COMPILER).$(BITS))

#
# Solaris linker flag sets to ease feature selection.  Add the required
# feature to your Makefile with LDFLAGS += $(FEATURE_MACRO) and add to the
# component build with CONFIGURE_OPTIONS += LDFLAGS="$(LDFLAGS)" or similiar.
#

# set the bittedness that we want to link
LD_BITS =	-$(BITS)

# Reduce the symbol table size, effectively conflicting with -g.  We should
# get linker guidance here.
LD_Z_REDLOCSYM =	-z redlocsym

# Cause the linker to rescan archive libraries and resolve remaining unresolved
# symbols recursively until all symbols are resolved.  Components should be
# linking in the libraries they need, in the required order.  This should
# only be required if the component's native build is horribly broken.
LD_Z_RESCAN_NOW =	-z rescan-now

LD_Z_TEXT =		-z text

# make sure that -lc is always present when building shared objects.
LD_DEF_LIBS +=		-lc

# make sure all symbols are defined.
LD_Z_DEFS =		-z defs

# eliminate unreferenced dynamic dependencies
LD_Z_IGNORE =		-z ignore

# eliminate comments
LD_Z_STRIP_CLASS =	-z strip-class=comment

# use direct binding
LD_B_DIRECT =		-Bdirect

# use generic macro names for enabling/disabling ASLR
ASLR_ENABLE = 		-z aslr=enable
ASLR_DISABLE = 		-z aslr=disable
ASLR_NOT_APPLICABLE = 	-z aslr=disable
ASLR_MODE = 		$(ASLR_DISABLE)

# by default, turn off Address Space Layout Randomization for ELF executables;
# to explicitly enable ASLR, set ASLR_MODE = $(ASLR_ENABLE)
# in that component's Makefile
LD_Z_ASLR =		$(ASLR_MODE)

#
# More Solaris linker flags that we want to be sure that everyone gets.  This
# is automatically added to the calling environment during the 'build' and
# 'install' phases of the component build.  Each individual feature can be
# turned off by adding FEATURE_MACRO= to the component Makefile.
#

# Create a non-executable stack when linking.
LD_MAP_NOEXSTK.i386 =	-M /usr/lib/ld/map.noexstk
LD_MAP_NOEXSTK.sparc =	-M /usr/lib/ld/map.noexstk

# Create a non-executable bss segment when linking.
LD_MAP_NOEXBSS =	-M /usr/lib/ld/map.noexbss

# Create a non-executable data segment when linking.  Due to PLT needs, the
# data segment must be executable on sparc, but the bss does not.
# see mapfile comments for more information
LD_MAP_NOEXDATA.i386 =	-M /usr/lib/ld/map.noexdata
LD_MAP_NOEXDATA.sparc =	$(LD_MAP_NOEXBSS)

# Page alignment
LD_MAP_PAGEALIGN =	-M /usr/lib/ld/map.pagealign

# Linker options to add when only building libraries
LD_OPTIONS_SO +=	$(LD_Z_TEXT) $(LD_Z_DEFS) $(LD_DEF_LIBS)

# Default linker options that everyone should get.  Do not add additional
# libraries to this macro, as it will apply to everything linked during the
# component build.
LD_OPTIONS +=	$(LD_MAP_NOEXSTK.$(MACH)) $(LD_MAP_NOEXDATA.$(MACH)) \
		$(LD_MAP_PAGEALIGN) $(LD_B_DIRECT) $(LD_Z_IGNORE) \
		$(LD_Z_STRIP_CLASS)

# only used on executables
LD_EXEC_OPTIONS = $(LD_Z_ASLR)

# Environment variables and arguments passed into the build and install
# environment(s).  These are the initial settings.
COMPONENT_BUILD_ENV= \
    LD_OPTIONS="$(LD_OPTIONS)" \
    LD_EXEC_OPTIONS="$(LD_EXEC_OPTIONS)"
COMPONENT_INSTALL_ENV= \
    LD_OPTIONS="$(LD_OPTIONS)" \
    LD_EXEC_OPTIONS="$(LD_EXEC_OPTIONS)"

# Add any bit-specific settings
COMPONENT_BUILD_ENV += $(COMPONENT_BUILD_ENV.$(BITS))
COMPONENT_BUILD_ARGS += $(COMPONENT_BUILD_ARGS.$(BITS))
COMPONENT_INSTALL_ENV += $(COMPONENT_INSTALL_ENV.$(BITS))
COMPONENT_INSTALL_ARGS += $(COMPONENT_INSTALL_ARGS.$(BITS))

# declare these phony so that we avoid filesystem conflicts.
.PHONY:	prep build install publish test clean clobber parfait

# If there are no tests to execute
NO_TESTS =	test-nothing
test-nothing:
	@echo "There are no tests available at this time."

# If the system tests are not implemented yet
SYSTEM_TESTS_NOT_IMPLEMENTED = no-sys-tests
no-sys-tests:
	@echo "The system test target is not yet implemented."

# There are tests, but we're skipping them.
SKIP_TEST =	skip-test
skip-test:
	@echo "Skipping tests"

# default behaviour for 'component-hook' target is to echo the component
# name and version information, but more complex behaviour can be implemented
# via command line setting of the COMPONENT_HOOK macro.
COMPONENT_HOOK ?=	echo $(COMPONENT_NAME) $(COMPONENT_VERSION)

component-hook:
	@$(COMPONENT_HOOK)

CLEAN_PATHS +=	$(BUILD_DIR)
CLOBBER_PATHS +=	$(PROTO_DIR)

#
# Packages with tools that are required to build Userland components
#
REQUIRED_PACKAGES += developer/build/gnu-make
REQUIRED_PACKAGES += developer/build/make
ifeq ($(COMPILER),gcc3)
REQUIRED_PACKAGES += developer/gcc-3
endif
ifeq ($(COMPILER),gcc)
REQUIRED_PACKAGES += developer/gcc-48
endif
ifeq ($(COMPILER),studio)
ifneq ($(findstring /opt/solarisstudio12.4,$(CC)),)
# If we are setup to build with an installed compiler, require the package
# we can uncomment this when we know that pkglint can find it.
#REQUIRED_PACKAGES += /solarisstudio/developer/solarisstudio-124
endif
endif
ifeq ($(PARFAIT_BUILD),yes)
# uncomment this line if you need to install Parfait
#REQUIRED_PACKAGES += developer/parfait/parfait-tools-161
endif
REQUIRED_PACKAGES += developer/versioning/mercurial
REQUIRED_PACKAGES += file/gnu-findutils
REQUIRED_PACKAGES += package/pkg
REQUIRED_PACKAGES += runtime/python-27
REQUIRED_PACKAGES += shell/bash
REQUIRED_PACKAGES += shell/ksh93
REQUIRED_PACKAGES += system/linker
REQUIRED_PACKAGES += text/gawk
REQUIRED_PACKAGES += text/gnu-grep
REQUIRED_PACKAGES += text/gnu-sed
REQUIRED_PACKAGES += developer/java/jdk-7
REQUIRED_PACKAGES += developer/java/jdk-8
REQUIRED_PACKAGES += security/sudo

include $(WS_MAKE_RULES)/environment.mk

# A simple rule to print the value of any macro.  Ex:
#   $ gmake print-REQUIRED_PACKAGES
# Note that some macros are set on a per target basis, so what you see
# is not always what you get.
print-%:
	@echo '$(subst ','\'',$*=$($*)) (origin: $(origin $*), flavor: $(flavor $*))'
