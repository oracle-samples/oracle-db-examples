/**
 * Copyright (c) 2023 Oracle and/or its affiliates.
 * Licensed under the Universal Permissive License v 1.0 as shown at https://oss.oracle.com/licenses/upl.
 */
package com.oracle.saga.travelagency.data;

import java.io.Serializable;
import java.util.List;

public class PersistentQueueValidation implements Serializable {
    private static final long serialVersionUID = -2835270122909650625L;
    private boolean isAllPersistentQueueValid;
    private int vUsersCount;
    private List<PersistentQueueDetails> persistentQueues;

    /**
     * True if the values in all the relevant persistent queues enqueue and dequeue message counts
     * are the expected values, otherwise false is returned.
     * 
     * @return the isAllPersistentQueueValid
     */
    public boolean isAllPersistentQueueValid() {
        return isAllPersistentQueueValid;
    }

    /**
     * Sets a boolean value for the isAllPersistentQueueValid
     * 
     * @param isAllPersistentQueueValid the isAllPersistentQueueValid to set
     */
    public void setAllPersistentQueueValid(boolean isAllPersistentQueueValid) {
        this.isAllPersistentQueueValid = isAllPersistentQueueValid;
    }

    /**
     * Gets the virtual user count.
     * 
     * @return the vUsersCount
     */
    public int getvUsersCount() {
        return vUsersCount;
    }

    /**
     * Sets the virtual user count.
     * 
     * @param vUsersCount the vUsersCount to set
     */
    public void setvUsersCount(int vUsersCount) {
        this.vUsersCount = vUsersCount;
    }

    /**
     * Gets a list of the different queues and some of the information related to it.
     * 
     * @return the persistentQueues
     */
    public List<PersistentQueueDetails> getPersistentQueues() {
        return persistentQueues;
    }

    /**
     * Sets a list of the different queues and some of the information related to it.
     * 
     * @param persistentQueues the persistentQueues to set
     */
    public void setPersistentQueues(List<PersistentQueueDetails> persistentQueues) {
        this.persistentQueues = persistentQueues;
    }

    /*
     * (non-Javadoc)
     * 
     * @see java.lang.Object#toString()
     */

    @Override
    public String toString() {
        return "PersistentQueueValidation [isAllPersistentQueueValid=" + isAllPersistentQueueValid
                + ", persistentQueues=" + persistentQueues + ", vUsersCount=" + vUsersCount + "]";
    }

}
