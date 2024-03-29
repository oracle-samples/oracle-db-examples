/**
 * Copyright (c) 2023 Oracle and/or its affiliates.
 * Licensed under the Universal Permissive License v 1.0 as shown at https://oss.oracle.com/licenses/upl.
 */
package com.oracle.saga.travelagency.data;

import java.io.Serializable;

public class PersistentQueueDetails implements Serializable {
    private static final long serialVersionUID = -6432481923974204490L;
    private String queueName;
    private int enqueuedMsgs;
    private int dequeuedMsgs;
    private boolean isEnqueueMsgsCountValid;
    private boolean isDequeueMsgsCountValid;

    /**
     * Gets the name of the persistent queue.
     * 
     * @return the queueName
     */
    public String getQueueName() {
        return queueName;
    }

    /**
     * Sets the name of the persistent queue.
     * 
     * @param queueName the queueName to set
     */
    public void setQueueName(String queueName) {
        this.queueName = queueName;
    }

    /**
     * Gets the count of the enqueue messages.
     * 
     * @return the enqueuedMsgs
     */
    public int getEnqueuedMsgs() {
        return enqueuedMsgs;
    }

    /**
     * Sets the count of the enqueue messages.
     * 
     * @param enqueuedMsgs the enqueuedMsgs to set
     */
    public void setEnqueuedMsgs(int enqueuedMsgs) {
        this.enqueuedMsgs = enqueuedMsgs;
    }

    /**
     * Returns true if the enqueue message count is the expected value otherwise false.
     * 
     * @return the isEnqueueMsgsCountValid
     */
    public boolean isEnqueueMsgsCountValid() {
        return isEnqueueMsgsCountValid;
    }

    /**
     * Sets a boolean value indictating whether the enqueue message count is the expected value or
     * not.
     * 
     * @param isEnqueueMsgsCountValid the isEnqueueMsgsCountValid to set
     */
    public void setEnqueueMsgsCountValid(boolean isEnqueueMsgsCountValid) {
        this.isEnqueueMsgsCountValid = isEnqueueMsgsCountValid;
    }

    /**
     * Gets the count of the dequeue messages.
     * 
     * @return the dequeuedMsgs
     */
    public int getDequeuedMsgs() {
        return dequeuedMsgs;
    }

    /**
     * Sets the count of the dequeue messages.
     * 
     * @param dequeuedMsgs the dequeuedMsgs to set
     */
    public void setDequeuedMsgs(int dequeuedMsgs) {
        this.dequeuedMsgs = dequeuedMsgs;
    }

    /**
     * Returns true if the dequeue message count is the expected value otherwise false.
     * 
     * @return the isDequeueMsgsCountValid
     */
    public boolean isDequeueMsgsCountValid() {
        return isDequeueMsgsCountValid;
    }

    /**
     * Returns true if the enqueue message count is the expected value otherwise false.
     * 
     * @param isDequeueMsgsCountValid the isDequeueMsgsCountValid to set
     */
    public void setDequeueMsgsCountValid(boolean isDequeueMsgsCountValid) {
        this.isDequeueMsgsCountValid = isDequeueMsgsCountValid;
    }

    /*
     * (non-Javadoc)
     * 
     * @see java.lang.Object#toString()
     */

    @Override
    public String toString() {
        return "PersistentQueueDetails [queueName=" + queueName + ", dequeuedMsgs=" + dequeuedMsgs
                + ", enqueuedMsgs=" + enqueuedMsgs + ", isDequeueMsgsCountValid="
                + isDequeueMsgsCountValid + ", isEnqueueMsgsCountValid=" + isEnqueueMsgsCountValid
                + "]";
    }

}
