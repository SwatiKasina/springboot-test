package com.example.demo.controller;

import org.springframework.beans.factory.annotation.Value;
import org.springframework.web.bind.annotation.GetMapping;
import org.springframework.web.bind.annotation.RequestMapping;
import org.springframework.web.bind.annotation.RestController;

@RestController
@RequestMapping("/api")
public class HelloController {

    @Value("${gateway.message:Hello World from Gateway Service!}")
    private String message;

    @Value("${gateway.environment:default}")
    private String environment;

    @GetMapping("/hello")
    public HelloResponse hello() {
        return new HelloResponse(message, environment);
    }

    public static class HelloResponse {
        private String message;
        private String environment;
        private long timestamp;

        public HelloResponse(String message, String environment) {
            this.message = message;
            this.environment = environment;
            this.timestamp = System.currentTimeMillis();
        }

        public String getMessage() {
            return message;
        }

        public void setMessage(String message) {
            this.message = message;
        }

        public String getEnvironment() {
            return environment;
        }

        public void setEnvironment(String environment) {
            this.environment = environment;
        }

        public long getTimestamp() {
            return timestamp;
        }

        public void setTimestamp(long timestamp) {
            this.timestamp = timestamp;
        }
    }
}
