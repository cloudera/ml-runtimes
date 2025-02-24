#!/bin/sh
exec java -jar /usr/local/share/chunker/ScalaChunker-assembly-1.1.jar
# for debug
#tee -a /tmp/chunker.in | java -jar /usr/local/share/chunker/ScalaChunker-assembly-1.1.jar | tee -a /tmp/chunker.out
