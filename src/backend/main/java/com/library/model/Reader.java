package com.library.model;

/**
 * 读者实体。
 */
public class Reader {

    private int readerId;
    private String name;
    private String phone;
    private String status;

    public Reader() {
    }

    public Reader(int readerId, String name, String phone, String status) {
        this.readerId = readerId;
        this.name = name;
        this.phone = phone;
        this.status = status;
    }

    public int getReaderId() {
        return readerId;
    }

    public void setReaderId(int readerId) {
        this.readerId = readerId;
    }

    public String getName() {
        return name;
    }

    public void setName(String name) {
        this.name = name;
    }

    public String getPhone() {
        return phone;
    }

    public void setPhone(String phone) {
        this.phone = phone;
    }

    public String getStatus() {
        return status;
    }

    public void setStatus(String status) {
        this.status = status;
    }

    @Override
    public String toString() {
        return "Reader{readerId=" + readerId + ", name='" + name + "', phone='" + phone
                + "', status='" + status + "'}";
    }
}
