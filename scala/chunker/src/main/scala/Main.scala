package chunker

import java.net.URLDecoder
import io.circe.Printer
import scala.io.Source
import io.circe.parser.decode

/** The runnable entry point for the parser application
 */
object Main extends App {
  val parser = new ScalaParser()
  val printer = Printer.noSpaces.copy(dropNullValues = true)

  // tell wsg-launcher that we're ready
  println("ML_RUNTIME_PARSER_READY")

  // each line expected to be encoded with utf-8
  // to have correct escaping of special chars
  for (ln <- Source.stdin.getLines()) {
    decode[String](ln) match {
      case Right(input) => println(printer.pretty(parser.parse(input)))
      case Left(err) => Console.err.println("json decode failed: " + err)
    }
  }
}
