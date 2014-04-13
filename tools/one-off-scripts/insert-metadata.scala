import java.io.{ File, PrintWriter }
import scala.io.Source

val shelfmarkMap = Source.fromFile("shelfmark-map.txt").getLines.toList.map { line =>
  val Array(shelfmark, folio) = line.drop(24).split(", fol. ")
  val id = line.take(22)

  val lines = Source.fromFile(s"../../data/tei/ox/${ id.dropRight(5) }/$id.xml").getLines.toList

  val Lry = """^(.*lry="\d+")(.*)$""".r

  val newLines = lines.map {
    case line @ Lry(before, after) => 
      val indentation = line.takeWhile(_ == ' ')
      val newStuff = s"""mith:shelfmark="$shelfmark" mith:folio="$folio""""
      s"$before\n$indentation$newStuff$after"
    case other => other
  }

  val outputDir = new File("output", id.dropRight(5))
  outputDir.mkdir()

  val pw = new PrintWriter(new File(outputDir, s"$id.xml"))
  newLines.foreach(pw.println)
  pw.close()
}

