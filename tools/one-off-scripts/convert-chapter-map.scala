import scala.io.Source

val Line = """^((?:.+)-(\d\d\d\d))\s+([^,]+),\s([^#]+)(\s#.+)?$""".r
val lines = Source.fromFile(args(0)).getLines.toList

case class Item(
  id: String,
  seq: Int,
  shelfmark: String,
  leaf: String,
  comment: Option[String]
)

val chapters: List[((String, String), List[Item])] = lines.foldLeft((
  List.empty[((String, String), List[Item])],
  (("", ""), List.empty[Item])
)) {
  case ((list, (name, current)), Line(id, seq, shelfmark, leaf, comment)) =>
    (list, (name, current :+ Item(id, seq.toInt, shelfmark, leaf, Option(comment).map(_.drop(2)))))

  case ((list, (name, current)), line) if line.isEmpty =>
    (list :+ (name, current), (("", ""), List.empty[Item]))

  case ((list, (name, current)), line) =>
    line.split(",").map(_.trim) match {
      case Array(volume, chapter) => (list, ((volume, chapter), current))
      case other => (list, (("", ""), current))
    }
}._1

type Locus = Either[(String, String), List[String]]

def compress(items: List[Item]): List[Locus] = {
  val (loci, (locus, last)) = items.foldLeft[(List[Locus], (Locus, Int))]((
    List.empty[Locus],
    (Right(Nil), -1)
  )) {
    case ((list, (locus, _)), Item(id, _, _, _, Some(comment))) =>
      (list :+ locus :+ Left((id, comment)), (Right(Nil), -1))
    case ((list, (Right(ids), last)), Item(id, seq, _, _, _)) if seq == last + 1 =>
      (list, (Right(ids :+ id), seq))
    case ((list, (locus @ Right(ids), last)), Item(id, seq, _, _, _)) =>
      (list :+ locus, (Right(List(id)), seq))
  }

  (loci :+ locus).filterNot {
    case Right(Nil) => true
    case _ => false
  }
}

val volumeName = chapters.map(_._1._1).groupBy(identity).mapValues(_.size).toList.sortBy(-_._2).head._1
val volumeNumber = volumeName.split(" ")(1)

def toId(id: String) = id.split("-") match {
  case Array(_, shelfmark, seq) if shelfmark.endsWith("c57") && seq.toInt <= 36 =>
    "ox-frankenstein_notebook_a.xml#" + id
  case Array(_, shelfmark, seq) if shelfmark.endsWith("c58") && seq.toInt >= 37 =>
    "ox-frankenstein_notebook_c2.xml#" + id
  case _ => "#" + id
}

def locusXml(locus: Locus) = locus match {
  case Right(ids) => f"""
                                        <locus target="${ids.map(toId).mkString(" ")}"/>"""
  case Left((id, comment)) => f"""
                                        <locus target="${toId(id)}">${comment.trim}</locus>"""
}

val chapterXml = chapters.filter(_._1._1.nonEmpty).map {
  case ((volume, chapter), items) =>
    val loci = compress(items)

    val chapterNumber = chapter.split(" ")(1)

    f"""
                                <msItem type="#chapter" n="$chapterNumber">
                                    <bibl>
                                        <title>$chapter</title>
                                    </bibl>
                                    <locusGrp>${ loci.map(locusXml).mkString }
                                    </locusGrp>
                                </msItem>"""
}.mkString

val otherXml = chapters.filterNot(_._1._1.nonEmpty).flatMap(_._2) match {
  case items =>
    val loci = compress(items)

    f"""
                            <msItem type="#miscellaneous">
                                <locusGrp>${ loci.map(locus => "\n" + locusXml(locus).drop(5)).mkString }
                                </locusGrp>
                            </msItem>"""
}

println(f"""
                            $otherXml
                            <msItem type="#volume" n="$volumeNumber" xml:id="">
                                <bibl>
                                    <title>$volumeName</title>
                                    <date></date>
                                </bibl>$chapterXml
                            </msItem>
""")

