package com.ClassicQueue.config;

import com.fasterxml.jackson.core.JsonProcessingException;
import com.fasterxml.jackson.core.type.TypeReference;
import com.fasterxml.jackson.databind.ObjectMapper;
import com.fasterxml.jackson.databind.SerializationFeature;

import java.io.IOException;

public class JsonUtils {
    private final ObjectMapper json;
    public JsonUtils() {
        json = new ObjectMapper();
        json.configure(SerializationFeature.WRITE_DATES_AS_TIMESTAMPS, false);
    }
    public static ObjectMapper json() {
        return InstanceHolder.json.json;
    }
    public static <T> T read(String src, Class<T> valueType) {
        try {
            return json().readValue(src, valueType);
        } catch (IOException e) {
            throw new IllegalStateException(e);
        }
    }
    public static <T> T read(String src, TypeReference<T> valueTypeRef) {
        try {
            return json().readValue(src, valueTypeRef);
        } catch (IOException e) {
            throw new IllegalStateException(e);
        }
    }
    public static <T> T read(byte[] src, Class<T> valueType) {
        try {
            return json().readValue(src, valueType);
        } catch (IOException e) {
            throw new IllegalStateException(e);
        }
    }
    public static <T> T read(byte[] src, TypeReference<T> valueTypeRef) {
        try {
            return json().readValue(src, valueTypeRef);
        } catch (IOException e) {
            throw new IllegalStateException(e);
        }
    }
    public static String writeValueAsString(Object value) {
        try {
            return json().writeValueAsString(value);
        } catch (JsonProcessingException e) {
            throw new IllegalStateException(e);
        }
    }
    public static byte[] writeValueAsBytes(Object value) {
        try {
            return json().writeValueAsBytes(value);
        } catch (JsonProcessingException e) {
            throw new IllegalStateException(e);
        }
    }
    private static class InstanceHolder {
        static final JsonUtils json = new JsonUtils();
    }
}