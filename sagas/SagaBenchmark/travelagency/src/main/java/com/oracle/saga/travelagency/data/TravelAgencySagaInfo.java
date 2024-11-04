/**
 * Copyright (c) 2023 Oracle and/or its affiliates.
 * Licensed under the Universal Permissive License v 1.0 as shown at https://oss.oracle.com/licenses/upl.
 */
package com.oracle.saga.travelagency.data;

import java.io.Serializable;
import java.util.HashSet;
import java.util.Set;

public class TravelAgencySagaInfo implements Serializable {
    private static final long serialVersionUID = 3009836270751992836L;
    private String sagaId;
    private Set<String> replies;
    private boolean bookFlight;
    private boolean bookHotel;
    private boolean bookCar;
    private boolean invokeError;
    private boolean rollbackPerformed;

    public TravelAgencySagaInfo() {
        replies = new HashSet<>();
    }

    public Set<String> getReplies() {
        return this.replies;
    }

    public void addReply(String participant) {
        replies.add(participant);
    }

    public void setSagaId(String sagaId) {
        this.sagaId = sagaId;
    }

    public void setBookFlight(boolean bookFlight) {
        this.bookFlight = bookFlight;
    }

    public void setBookHotel(boolean bookHotel) {
        this.bookHotel = bookHotel;
    }

    public void setBookCar(boolean bookCar) {
        this.bookCar = bookCar;
    }

    public void setInvokeError(boolean invokeError) {
        this.invokeError = invokeError;
    }

    public void setRollbackPerformed(boolean rollbackPerformed) {
        this.rollbackPerformed = rollbackPerformed;
    }

    public String getSagaId() {
        return this.sagaId;
    }

    public boolean getBookFlight() {
        return this.bookFlight;
    }

    public boolean getBookHotel() {
        return this.bookHotel;
    }

    public boolean getBookCar() {
        return this.bookCar;
    }

    public boolean getInvokeError() {
        return this.invokeError;
    }

    public boolean getRollbackPerformed() {
        return this.rollbackPerformed;
    }

    @Override
    public String toString() {
        StringBuilder builder = new StringBuilder();
        builder.append("TravelAgencySagaInfo [sagaId=");
        builder.append(sagaId);
        builder.append(", replies=");
        builder.append(replies.toString());
        builder.append(", bookFlight=");
        builder.append(bookFlight);
        builder.append(", bookHotel=");
        builder.append(bookHotel);
        builder.append(", bookCar=");
        builder.append(bookCar);
        builder.append(", invokeError=");
        builder.append(invokeError);
        builder.append(", rollbackPerformed=");
        builder.append(rollbackPerformed);
        builder.append("]");
        return builder.toString();
    }
}
