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

	export CPPFLAGS=${cppflags[$cc]} 
	export CC=${alias[$cc]:-$cc} 
	export CXX=${CC/gcc/g++}
	
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
		make clean && make PLATFORM=$platform -j8
		cd $pwd
		
		cp $subitem/build/lib$subitem.a $target
		mkdir -p $target/include/$subitem
		cp -u $subitem/ixmlextra.h $_
	fi
	
	# finally concatenate all in a thin
	rm -f $target/$library
	ar -rc --thin $target/$library $target/*.a
done


