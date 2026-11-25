package com.library.service;

/**
 * Service 层统一异常：把 SQLException 转成带业务上下文的运行时异常。
 */
public class ServiceException extends RuntimeException {

    public ServiceException(String message, Throwable cause) {
        super(message, cause);
    }
}
