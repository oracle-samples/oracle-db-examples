package com.oracle.saga.cloudbank.data;

import com.fasterxml.jackson.core.JsonProcessingException;
import com.fasterxml.jackson.databind.ObjectMapper;

import java.util.Objects;

/**
 * Accounts is a class which holds the basic variables/fields required for Accounts JSON request.
 */
public class Accounts {

    @Override
    public boolean equals(Object o) {
        if (this == o) return true;
        if (!(o instanceof Accounts)) return false;
        var accounts = (Accounts) o;
        return Objects.equals(getOperationType(), accounts.getOperationType()) && Objects.equals(ucid, accounts.ucid) && Objects.equals(transactionType, accounts.transactionType) && Objects.equals(transactionAmount, accounts.transactionAmount) && Objects.equals(accountType, accounts.accountType) && Objects.equals(balanceAmount, accounts.balanceAmount) && Objects.equals(accountNumber, accounts.accountNumber);
    }

    @Override
    public int hashCode() {
        return Objects.hash(getOperationType(), ucid, transactionType, transactionAmount, accountType, balanceAmount, accountNumber);
    }

    @Override
    public String toString() {
        try {
            return new ObjectMapper().writeValueAsString(this);
        } catch (JsonProcessingException e) {
            return "";
        }
    }

    public String getOperationType() {
        return operationType;
    }

    public void setOperationType(String operationType) {
        this.operationType = operationType;
    }

    public String getUcid() {
        return ucid;
    }

    public void setUcid(String ucid) {
        this.ucid = ucid;
    }

    public String getTransactionType() {
        return transactionType;
    }

    public void setTransactionType(String transactionType) {
        this.transactionType = transactionType;
    }

    public String getTransactionAmount() {
        return transactionAmount;
    }

    public void setTransactionAmount(String transactionAmount) {
        this.transactionAmount = transactionAmount;
    }

    public String getAccountType() {
        return accountType;
    }

    public void setAccountType(String accountType) {
        this.accountType = accountType;
    }

    public String getBalanceAmount() {
        return balanceAmount;
    }

    public void setBalanceAmount(String balanceAmount) {
        this.balanceAmount = balanceAmount;
    }

    public String getAccountNumber() {
        return accountNumber;
    }

    public void setAccountNumber(String accountNumber) {
        this.accountNumber = accountNumber;
    }

    private String operationType;
    private String ucid;
    private String transactionType;
    private String transactionAmount;
    private String accountType;
    private String balanceAmount;
    private String accountNumber;

}
