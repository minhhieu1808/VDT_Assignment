import org.apache.spark.sql.SparkSession
import org.apache.spark.sql.functions.{col, date_format, sum, to_date}
import org.apache.spark.sql.types.IntegerType

object Main {
  def main(args: Array[String]): Unit = {
    val spark = SparkSession
      .builder
      .master("local")
      .appName("VdtAssigment")
      .getOrCreate()
    spark.sparkContext.setLogLevel("ERROR")
    spark.sql("set spark.sql.legacy.timeParserPolicy=LEGACY")
    val activities = spark.read.parquet("/raw_zone/fact/activity")
      .withColumn("numberOfFile", col("numberOfFile").cast(IntegerType))
    val studentList = spark.read.option("delimiter", ",").option("encoding", "UTF-8").csv("/raw_zone/student_list/danh_sach_sv_de.csv")
      .toDF("student_code","student_name")
    activities.join(studentList, Seq("student_code"))
      .withColumn("date", date_format(to_date(col("timestamp"),"MM/dd/yyyy"),"yyyyMMdd"))
      .groupBy("date","student_code","student_name","activity")
      .agg(sum("numberOfFile").as("totalFile"))
      .filter(col("student_name") === "Nguyễn Minh Hiếu")
      .orderBy("date","activity")
      .write.mode("overwrite").option("encoding", "UTF-8").csv("/work_zone/student_activity")
  }
}