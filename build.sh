#!/bin/bash

list="x86_64-linux-gnu-gcc x86-linux-gnu-gcc arm-linux-gnueabi-gcc aarch64-linux-gnu-gcc sparc64-linux-gnu-gcc mips-linux-gnu-gcc powerpc-linux-gnu-gcc"
declare -A alias=( [x86-linux-gnu-gcc]=i686-linux-gnu-gcc )
declare -A cppflags=( [mips-linux-gnu-gcc]="-march=mips32" [powerpc-linux-gnu-gcc]="-m32")
declare -a compilers

IFS= read -ra candidates <<< "$list"

# do we have "clean" somewhere in parameters (assuming no compiler has "clean" in it...
if [[ $@[*]} =~ clean ]]; then
	clean="clean"
fi	

# first select platforms/compilers
for cc in ${candidates[@]}
do
	# check compiler first
	if ! command -v ${alias[$cc]:-$cc} &> /dev/null; then
		continue
	fi
	
	if [[ $# == 0 ]]; then
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

library=libpupnp.a

# bootstrap environment if needed
if [[ ! -f pupnp/configure ]]; then
	cd pupnp
	autoreconf -if
	cd ..
fi

# then iterate selected platforms/compilers
for cc in ${compilers[@]}
do
	IFS=- read -r platform host dummy <<< $cc

	target=targets/$host/$platform	
	
	if [[ -f $target/$library && -z $clean ]]; then
		continue
	fi

	pwd=$(pwd)
	cd pupnp
	export CPPFLAGS=${cppflags[$cc]} 
	export CC=${alias[$cc]:-$cc} 
	export CXX=${CC/gcc/g++}
	./configure --enable-static --disable-shared --disable-samples --host=$platform-$host 
	make clean && make
	cd $pwd
		
	mkdir -p $target
	mkdir -p $_/include
	for item in upnp ixml
	do
		cp pupnp/$item/.libs/lib$item.a $target
		ar -rc --thin $_/$library $_/lib$item.a 
		cp -ur pupnp/$item/inc/* $target/include
		find $_ -type f -not -name "*.h" -exec rm {} +
	done	
done


