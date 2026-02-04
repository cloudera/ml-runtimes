import sbtassembly.AssemblyPlugin
import sbtassembly.AssemblyPlugin.autoImport._

name := "ScalaChunker"

version := "1.1"

scalaVersion := "2.11.12"



enablePlugins(AssemblyPlugin)

Compile / mainClass := Some("chunker.Main")

assembly / test := {}

// sbt-assembly merge strategy rationale:
// - After migrating to sbt 1.x and sbt-assembly 0.14.x, dependencies often include
//   META-INF entries that conflict (duplicate MANIFESTs), are signed (e.g. *.SF/*.RSA),
//   or come from multi-release JARs (META-INF/versions/*). Keeping those can cause
//   assembly failures (duplicate entries) or invalid signature warnings/errors.
// - Older 0.13-era builds (and assemblySettings) tended to hide some of these conflicts.
//   With the newer toolchain we must be explicit.
// - We discard dependency META-INF content and keep only our assembly's own manifest.
//   If ServiceLoader resources are needed later, add a specific rule to concat
//   META-INF/services/* instead of discarding them.
assembly / assemblyMergeStrategy := {
  case PathList("META-INF", xs @ _*) => MergeStrategy.discard
  case x => (assembly / assemblyMergeStrategy).value(x)
}

libraryDependencies += "org.scalatest" %% "scalatest" % "2.2.4" % Test
libraryDependencies += "org.scala-lang" % "scala-reflect" % "2.11.12"
libraryDependencies += "org.scala-lang" % "scala-compiler" % "2.11.12" // for ToolBox
libraryDependencies += "io.circe" %% "circe-generic" % "0.11.2"
libraryDependencies += "io.circe" %% "circe-parser" % "0.11.2"
libraryDependencies += "org.scalameta" %% "scalameta" % "1.0.0" //for scala parsing and ast
