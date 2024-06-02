package org.vdt;


import org.apache.kafka.clients.producer.*;

import java.io.BufferedReader;
import java.io.FileReader;
import java.io.IOException;
import java.util.List;
import java.util.Properties;
import java.util.UUID;

public class CsvToKafka {
    private static final String TOPIC_NAME = "vdt2024";
    private static final String BOOTSTRAP_SERVERS = "192.168.233.209:9092,192.168.233.209:9093";
    private static final String dataPath = "C:\\Users\\Admin\\Downloads\\log_action.csv";

    private static void sendBatch(KafkaProducer<String, String> producer, List<ProducerRecord<String, String>> batchRecords) {
        for (ProducerRecord<String, String> record : batchRecords) {
            producer.send(record);
        }
        producer.flush();
    }

    public static void main(String[] args){
        Properties props = new Properties();
        props.put(ProducerConfig.BOOTSTRAP_SERVERS_CONFIG, BOOTSTRAP_SERVERS);
        props.put(ProducerConfig.KEY_SERIALIZER_CLASS_CONFIG, "org.apache.kafka.common.serialization.StringSerializer");
        props.put(ProducerConfig.VALUE_SERIALIZER_CLASS_CONFIG, "org.apache.kafka.common.serialization.StringSerializer");
        try (KafkaProducer<String, String> producer = new KafkaProducer<>(props);
             BufferedReader reader = new BufferedReader(new FileReader(dataPath))) {
            String line;
            int recordCount = 0;

            while ((line = reader.readLine()) != null) {
                // Process the CSV line and create a ProducerRecord
                String[] fields = line.split(",");
                String key = UUID.randomUUID().toString();  // Assuming the key is in the first column
                String object = "{\"student_code\":\"" + fields[0] + "\",\"activity\":\"" + fields[1] + "\",\"numberOfFile\":\"" + fields[2] + "\",\"timestamp\":\"" +  fields[3] + "\"}";
                ProducerRecord<String, String> record = new ProducerRecord<>(TOPIC_NAME, key, object);

                // Send the record and handle the result with callback
                producer.send(record, new Callback() {
                    @Override
                    public void onCompletion(RecordMetadata metadata, Exception exception) {
                        if (exception == null) {
                            System.out.println("Record id " + record.key() + " sent successfully - topic: " + metadata.topic() +
                                    ", partition: " + metadata.partition() +
                                    ", offset: " + metadata.offset());
                        } else {
                            System.err.println("Error while sending record " + record.key() + ": " + exception.getMessage());
                        }
                    }
                });

                recordCount++;
            }

            System.out.println(recordCount + " records sent to Kafka successfully.");
        } catch (IOException e) {
            System.out.println("Source not found or Can't connect to Kafka Broker");
        }
    }
}