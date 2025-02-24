package chunker

import io.circe.generic.auto._
import io.circe.syntax._

import scala.collection.mutable.ListBuffer
import scala.meta._

/** Umbrella for the formats of chunks that work with comment-chunk-helper:
 * https://www.npmjs.com/package/comment-chunk-helper
 */

case class CodeLocation(line: Int, column: Int)

case class ErrorJson(
                      error: String
                    )

case class ChunkJson(
                      start: CodeLocation,
                      end: CodeLocation,
                      `type`: Option[String],
                      message: Option[String]
                    )

/** Parses chunks out of an ast using http://scalameta.org/ */
class ScalaParser() {

  /** Return the Json of code/comment/error chunks engines expect (similar to
   * code chunk helper)
   *
   * @param code
   * the string representation of the entered code
   * @return
   * the string
   */
  def parse(code: String): io.circe.Json = {
    val codeChunks = new ListBuffer[ChunkJson]()

    // strip out the lines with magics and save them
    val magicFree = code
      .split("\n")
      .zipWithIndex
      .map {
        case (x, i) => {
          if (x.startsWith("%")) {
            codeChunks += ChunkJson(
              CodeLocation(i, 0),
              CodeLocation(i, x.length),
              Some("code"),
              None
            )
            ""
          } else {
            x
          }
        }
      }
      .mkString("\n")

    try {
      // need to work from one large "chunk", surround in brackets
      // the `.parse` is an extension function of scala-meta. this is where the actual parsing happens.
      val tree =
        s"""{
           |$magicFree
           |}
         """.stripMargin.parse[Term]

      // combine all code chunks
      codeChunks ++= tree.get.children.map(tree => {
        new ChunkJson(
          CodeLocation(tree.pos.start.line - 1, tree.pos.start.column),
          CodeLocation(tree.pos.end.line - 1, tree.pos.end.column),
          Some("code"),
          None
        )
      })
      // then sort them so magics are in the right positions
      codeChunks.sortBy(c => (c.start.line, c.start.column)).asJson

    } catch {
      case e: ParseException => ErrorJson(e.shortMessage).asJson
      case e: TokenizeException => ErrorJson(e.shortMessage).asJson
      case e: Throwable => ErrorJson(e.getMessage).asJson
    }
  }
}
