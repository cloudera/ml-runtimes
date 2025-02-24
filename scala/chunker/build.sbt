import AssemblyKeys._ // put this at the top of the file
assemblySettings
mainClass in assembly := Some("chunker.Main")

name := "ScalaChunker"

version := "1.1"

scalaVersion := "2.11.12"

libraryDependencies += "org.scalatest" %% "scalatest" % "2.2.4" % "test"
libraryDependencies += "org.scala-lang" % "scala-reflect" % "2.11.12"
libraryDependencies += "org.scala-lang" % "scala-compiler" % "2.11.12" // for ToolBox
libraryDependencies += "io.circe" %% "circe-generic" % "0.11.2"
libraryDependencies += "io.circe" %% "circe-parser" % "0.11.2"
libraryDependencies += "org.scalameta" %% "scalameta" % "1.0.0" //for scala parsing and ast
