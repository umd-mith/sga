import scala.xml._

val doc = XML.loadFile(args(0))

val msContents = doc \\ "msContents"

val misc = ((msContents \ "msItem" \ "msItem").filter(
  _.attributes.asAttrMap("type") == "#miscellaneous"
) \ "locusGrp" \ "locus").map(_.attributes.asAttrMap("target"))

val real = (msContents \ "msItem" \ "msItem" \ "msItem" \ "locusGrp" \ "locus").map(
  _.attributes.asAttrMap("target")
)

val volumeId =  (doc \\ "msItem").filter(
  _.attributes.asAttrMap("type") == "#volume"
).map(_.attributes.asAttrMap("xml:id")).head

def toFileName(ref: String) = ref.split("#") match {
  case Array(_, id) => id.split("-") match {
    case Array(lib, shelf, seq) => f"$lib-$shelf/$lib-$shelf-$seq.xml"
  }
}

def toVolumeId(ref: String) = ref.split("#") match {
  case Array("", id) => "#" + volumeId
  case Array(_, id) => args(0).split("/").last + "#" + volumeId
}

misc.flatMap(_.split(" ")).foreach { ref =>
  val file = toFileName(ref)

  println(f"""sed -i 's/ partOf="#[^"]*"//' $file""")
}
real.flatMap(_.split(" ")).foreach { ref =>
  val file = toFileName(ref)
  val volId = toVolumeId(ref)

  println(f"""sed -i 's/ partOf="#[^"]*"/ partOf="$volId"/' $file""")
}

