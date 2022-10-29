#!/bin/bash

list="x86_64-linux-gnu-gcc x86-linux-gnu-gcc armhf-linux-gnueabi-gcc aarch64-linux-gnu-gcc \
      sparc64-linux-gnu-gcc mips-linux-gnu-gcc powerpc-linux-gnu-gcc x86_64-macos-darwin-gcc \
	  x86_64-freebsd-gnu-gcc x86_64-solaris-gnu-gcc"

declare -A alias=( [x86-linux-gnu-gcc]=i686-stretch-linux-gnu-gcc \
				   [x86_64-linux-gnu-gcc]=x86_64-stretch-linux-gnu-gcc \
				   [armhf-linux-gnueabi-gcc]=armv7-stretch-linux-gnueabi-gcc \
				   [aarch64-linux-gnu-gcc]=aarch64-stretch-linux-gnu-gcc \
				   [sparc64-linux-gnu-gcc]=sparc64-stretch-linux-gnu-gcc \
				   [mips-linux-gnu-gcc]=mips64el-stretch-linux-gnu-gcc \
				   [powerpc-linux-gnu-gcc]=powerpc64-stretch-linux-gnu-gcc \
				   [x86_64-macos-darwin-gcc]=x86_64-apple-darwin19-gcc \
				   [x86_64-freebsd-gnu-gcc]=x86_64-cross-freebsd12.3-gcc \
				   [x86_64-solaris-gnu-gcc]=x86_64-cross-solaris2.x-gcc )

declare -A cflags=( [sparc64-linux-gnu-gcc]="-mcpu=v7" \
                    [mips-linux-gnu-gcc]="-march=mips32" \
                    [powerpc-linux-gnu-gcc]="-m32" )
					
declare -a compilers

IFS= read -ra candidates <<< "$list"

# do we have "clean" somewhere in parameters (assuming no compiler has "clean" in it...
if [[ $@[*]} =~ clean ]]; then
	clean="clean"
fi	

# first select platforms/compilers
for cc in ${candidates[@]}; do
	# check compiler first
	if ! command -v ${alias[$cc]:-$cc} &> /dev/null; then
		if command -v $cc &> /dev/null; then
			unset alias[$cc]
		else	
			continue
		fi	
	fi

	if [[ $# == 0 || ($# == 1 && -n $clean) ]]; then
		compilers+=($cc)
		continue
	fi

	for arg in $@
	do
		if [[ $cc =~ $arg ]]; then 
			compilers+=($cc)
		fi
	done
done

item=pupnp
library=lib$item.a
pwd=$(pwd)

# bootstrap environment if needed
if [[ ! -f $item/configure && -f $item/configure.ac ]]; then
	cd $item
	if [[ -f autogen.sh ]]; then
		./autogen.sh --no-symlinks
	else 	
		autoreconf -if
	fi	
	cd $pwd
fi	

# then iterate selected platforms/compilers
for cc in ${compilers[@]}
do
	IFS=- read -r platform host dummy <<< $cc

	target=targets/$host/$platform	
	
	if [ -f $target/$library ] && [[ -z $clean ]]; then
		continue
	fi

	export CFLAGS=${cflags[$cc]} 
	export CC=${alias[$cc]:-$cc} 
	export CXX=${CC/gcc/g++}
	export AR=${CC%-*}-ar
	export RANLIB=${CC%-*}-ranlib
	
	cd $item
	./configure --enable-static --disable-shared --disable-samples --host=$platform-$host 
	make clean && make -j8
	cd $pwd
		
	mkdir -p $target	
	for subitem in upnp ixml
	do
		cp $item/$subitem/.libs/lib$subitem.a $target
		mkdir -p $_/include/$subitem
		cp -ur $item/$subitem/inc/* $_
		find $_ -type f -not -name "*.h" -exec rm {} +
	done	
	
	# then build addons (all others *must* be built first)
	subitem=addons
	if [ ! -f $target/lib$subitem.a ] || [[ -n $clean ]]; then
		cd $subitem
		make clean && make HOST=$host PLATFORM=$platform -j8
		cd $pwd
		
		cp $subitem/build/lib$subitem.a $target
		mkdir -p $target/include/$subitem
		cp -u $subitem/ixmlextra.h $_
	fi
	
	# finally concatenate all in a thin (if possible)
	rm -f $target/$library
	if [[ $host =~ macos ]]; then
		# libtool will whine about duplicated symbols
		${CC%-*}-libtool -static -o $target/$library $target/*.a 
	else
		ar -rc --thin $target/$library $target/*.a	
	fi	
done


