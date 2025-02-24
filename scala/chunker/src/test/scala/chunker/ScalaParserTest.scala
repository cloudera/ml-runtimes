package chunker

import org.scalatest.FunSuite
import org.scalatest.Ignore
import io.circe._, io.circe.parser._

@Ignore
class ScalaParserTest extends FunSuite {
  val parser = new ScalaParser
  val printer = io.circe.Printer.noSpaces.copy(dropNullValues = true)

  test("parsing the code chunk helper example") {
    val code = """|// Here are some line comments.
                 |// Successive line comments should be grouped together in a chunk.
                 |// These chunks are often markdown-formatted and displayed as documentation.
                 |val a = 2
                 |val b = 2; val c = 3
                 |/*
                 |Here's a block comment. Block comments can be markdown-formatted and displayed
                 |as documentation too.
                 |*/
                 |def square( x:Int ) : Int = {
                 |  x*x
                 |}
                 |if (true) {
                 |  println(square(3))
                 |}
                 |else {
                 |  println("Not displaying the answer.");
                 |}
               """.stripMargin
    val result = parse(
      """
    [ {"start":{"line":3,"column":0},"end":{"line":3,"column":8},"type":"code"},
    {"start":{"line":4,"column":0},"end":{"line":4,"column":8},"type":"code"},
    {"start":{"line":4,"column":11},"end":{"line":4,"column":19},"type":"code"},
    {"start":{"line":9,"column":0},"end":{"line":11,"column":0},"type":"code"},
    {"start":{"line":12,"column":0},"end":{"line":17,"column":0},"type":"code"}]
      """).right.getOrElse(Json.Null)
    assert(parser.parse(code).pretty(printer) == result.pretty(printer))
  }

  test("parsing code without braces"){
    val code =
      """def square(x: Double) =
        |      x*x
        |println(square(2))
      """.stripMargin

    val result = parse(
      """
    [{"start":{"line":0,"column":0},"end":{"line":1,"column":8},"type":"code"},
    {"start":{"line":2,"column":0},"end":{"line":2,"column":17},"type":"code"}]
      """).right.getOrElse(Json.Null)
    assert(parser.parse(code).pretty(printer) == result.pretty(printer))
  }

  test("parsing an object, class, trait example"){

    //from: http://www.scala-lang.org/old/node/46.html
    val code = """import scala.collection.immutable.Seq
                 |
                 |object Configuration extends NewsContext {
                 |
                 |  lazy val news = new News
                 |
                 |  override lazy protected val channels = List(new SportsChannel, new MusicChannel)
                 |
                 |  override lazy protected val numberOfMessages = 2
                 |}
                 |
                 |trait NewsContext {
                 |
                 |  class News {
                 |    def latestMessages: Seq[String] =
                 |      channels flatMap { _.messages take numberOfMessages }
                 |  }
                 |
                 |  protected def channels: Seq[Channel]
                 |
                 |  protected def numberOfMessages: Int
                 |}
                 |
                 |trait Channel {
                 |  def messages: Seq[String]
                 |}
                 |
                 |class SportsChannel extends Channel {
                 |  override def messages =
                 |    "GER:ESP 0:1" :: "ARG:GER 0:4" :: "GER:ENG 4:1" :: Nil
                 |}
                 |
                 |class MusicChannel extends Channel {
                 |  override def messages =
                 |    "Eminem Recovery rocks!" :: "Hole Nobody's Daughter is great!" :: Nil
                 |}
                 |
                 |object NewsApp extends App {
                 |  Configuration.news.latestMessages foreach println
                 |}
               """.stripMargin

    val result = parse(
      """
    [{"start":{"line":0,"column":0},"end":{"line":0,"column":36},"type":"code"},
    {"start":{"line":2,"column":0},"end":{"line":9,"column":0},"type":"code"},
    {"start":{"line":11,"column":0},"end":{"line":21,"column":0},"type":"code"},
    {"start":{"line":23,"column":0},"end":{"line":25,"column":0},"type":"code"},
    {"start":{"line":27,"column":0},"end":{"line":30,"column":0},"type":"code"},
    {"start":{"line":32,"column":0},"end":{"line":35,"column":0},"type":"code"},
    {"start":{"line":37,"column":0},"end":{"line":39,"column":0},"type":"code"}]
      """).right.getOrElse(Json.Null)
    assert(parser.parse(code).pretty(printer) == result.pretty(printer))
  }

  test("parsing internal comments example"){
    val code =
      """|object HelloWorld { //here is an end comment
        |      def main(args: Array[String]) {
        |        println("Hello, world!")
        |        /* some more comments
        |        //with an inline in them
        |        */
        |      }
        |    }
      """.stripMargin
    val result = parse("""[{"start":{"line":0,"column":0},"end":{"line":7,"column":4},"type":"code"}]""").right.getOrElse(Json.Null)
    assert(parser.parse(code).pretty(printer) == result.pretty(printer))
  }

  test("has a block with a syntax error") {
    val code =
      """|object HelloWorld { //here is an end comment
        |      def main(args: Array[String]) {
        |        println("Hello, world!")
        |      }
        |    }
        | println(1
        | val a = 10
      """.stripMargin
    val result = parse("""{"start":{"line":6,"column":1},"end":{"line":6,"column":3},"type":"error","message":") expected but val found"}""").right.getOrElse(Json.Null)
    assert(parser.parse(code).pretty(printer) == result.pretty(printer))
  }

  test("parsing a single line chunk") {
    val code = "val a = 10"
    val result = parse("""[{"start":{"line":0,"column":0},"end":{"line":0,"column":9},"type":"code"}]""").right.getOrElse(Json.Null)
    assert(parser.parse(code).pretty(printer) == result.pretty(printer))
  }

  //http://danielwestheide.com/blog/2013/01/23/the-neophytes-guide-to-scala-part-10-staying-dry-with-higher-order-functions.html
  test("parsing a chaining example") {
    val code =
      """addMissingSubject = (email: Email) =>
        | if (email.subject.isEmpty) email.copy(subject = "No subject")
        | else email
        |val checkSpelling = (email: Email) =>
        | email.copy(text = email.text.replaceAll("your", "you're"))
        | val removeInappropriateLanguage = (email: Email) =>
        | email.copy(text = email.text.replaceAll("dynamic typing", "**CENSORED**"))
        | val addAdvertismentToFooter = (email: Email) =>
        |   email.copy(text = email.text + "\nThis mail sent via Super Awesome Free Mail")
        |
        |val pipeline = Function.chain(Seq(
        |  addMissingSubject,
        |  checkSpelling,
        |  removeInappropriateLanguage,
        |  addAdvertismentToFooter))
      """.stripMargin

    val result = parse(
      """
        |[{"start":{"line":0,"column":0},"end":{"line":2,"column":10},"type":"code"},
        |{"start":{"line":3,"column":0},"end":{"line":4,"column":58},"type":"code"},
        |{"start":{"line":5,"column":1},"end":{"line":6,"column":74},"type":"code"},
        |{"start":{"line":7,"column":1},"end":{"line":8,"column":80},"type":"code"},
        |{"start":{"line":10,"column":0},"end":{"line":14,"column":26},"type":"code"}]""".stripMargin).right.getOrElse(Json.Null)
    assert(parser.parse(code).pretty(printer) == result.pretty(printer))
  }

  test("quotes newlines") {
    val code = """var a = "hello\nGoodbye""""

    val result = parse(
      """[{"start":{"line":0,"column":0},"end":{"line":0,"column":23},"type":"code"}]""".stripMargin).right.getOrElse(Json.Null)
    assert(parser.parse(code).pretty(printer) == result.pretty(printer))
  }

  test("a single magic") {
    val code = """%%AddDeps org.apache.spark spark-streaming-kafka_2.10 1.1.0 --transitive"""

    val result = parse(
      """[{"start":{"line":0,"column":0},"end":{"line":0,"column":71},"type":"code"}]""".stripMargin).right.getOrElse(Json.Null)
    assert(parser.parse(code).pretty(printer) == result.pretty(printer))
  }

  test("magics within a code block ") {
    val code =
      """
        |var a = 11;
        |println(a);
        |
        |%AddDeps org.apache.spark spark-streaming-kafka_2.10 1.1.0 --transitive
        |%AddDeps org.apache.spark some-random-package 6.4.0
        |
        |1 to 100.reduce(_+_)
        |""".stripMargin

    val result = parse(
      """
        |[{"start":{"line":1,"column":0},"end":{"line":1,"column":9},"type":"code"},
        |{"start":{"line":2,"column":0},"end":{"line":2,"column":9},"type":"code"},
        |{"start":{"line":4,"column":0},"end":{"line":4,"column":70},"type":"code"},
        |{"start":{"line":5,"column":0},"end":{"line":5,"column":50},"type":"code"},
        |{"start":{"line":7,"column":0},"end":{"line":7,"column":19},"type":"code"}]
      """.stripMargin).right.getOrElse(Json.Null)
    assert(parser.parse(code).pretty(printer) == result.pretty(printer))
  }
  test("non-character single quote errors should be caught ") {
    val code = """var a = 'this isn't a char'"""

    val result = parse(
      """
        |{"start":{"line":0,"column":26},"end":{"line":0,"column":25},
        |"type":"error","message":"unclosed character literal"}
      """.stripMargin).right.getOrElse(Json.Null)
    assert(parser.parse(code).pretty(printer) == result.pretty(printer))
  }
  test("Unclosed string literals should be caught") {
    val code = """var a = "close your string literals! """

    val result = parse(
      """
        |{"start":{"line":0,"column":8},"end":{"line":0,"column":7},
        |"type":"error","message":"unclosed string literal"}
      """.stripMargin).right.getOrElse(Json.Null)
    assert(parser.parse(code).pretty(printer) == result.pretty(printer))
  }
}
