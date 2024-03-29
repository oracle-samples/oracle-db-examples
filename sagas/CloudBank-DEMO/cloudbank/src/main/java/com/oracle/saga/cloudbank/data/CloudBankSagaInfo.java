/**
 * Copyright (c) 2024 Oracle and/or its affiliates.
 * Licensed under the Universal Permissive License v 1.0 as shown at https://oss.oracle.com/licenses/upl.
 */
package com.oracle.saga.cloudbank.data;

import com.fasterxml.jackson.core.JsonProcessingException;
import com.fasterxml.jackson.databind.ObjectMapper;

import java.util.HashSet;
import java.util.Set;

/**
 * CloudBankSagaInfo is a class which holds the saga's info and is used to store in the cache.
 */
public class CloudBankSagaInfo {

    public String getSagaId() {
        return sagaId;
    }

    public void setSagaId(String sagaId) {
        this.sagaId = sagaId;
    }

    public void setReplies(Set<String> replies) {
        this.replies = replies;
    }

    public boolean isAccounts() {
        return accounts;
    }

    public void setAccounts(boolean accounts) {
        this.accounts = accounts;
    }

    public boolean isNewBA() {
        return newBA;
    }

    public void setNewBA(boolean newBA) {
        this.newBA = newBA;
    }

    public boolean isNewCC() {
        return newCC;
    }

    public void setNewCC(boolean newCC) {
        this.newCC = newCC;
    }

    public boolean isViewAll() {
        return viewAll;
    }

    public void setViewAll(boolean viewAll) {
        this.viewAll = viewAll;
    }

    public boolean isViewBA() {
        return viewBA;
    }

    public void setViewBA(boolean viewBA) {
        this.viewBA = viewBA;
    }

    public boolean isViewCC() {
        return viewCC;
    }

    public void setViewCC(boolean viewCC) {
        this.viewCC = viewCC;
    }

    public boolean isViewCS() {
        return viewCS;
    }

    public void setViewCS(boolean viewCS) {
        this.viewCS = viewCS;
    }

    public boolean isAccTransfer() {
        return accTransfer;
    }

    public void setAccTransfer(boolean accTransfer) {
        this.accTransfer = accTransfer;
    }

    public boolean isNewCustomer() {
        return newCustomer;
    }

    public void setNewCustomer(boolean newCustomer) {
        this.newCustomer = newCustomer;
    }

    public boolean isInvokeError() {
        return invokeError;
    }

    public void setInvokeError(boolean invokeError) {
        this.invokeError = invokeError;
    }

    public boolean isRollbackPerformed() {
        return rollbackPerformed;
    }

    public void setRollbackPerformed(boolean rollbackPerformed) {
        this.rollbackPerformed = rollbackPerformed;
    }

    public boolean isAccountsResponse() {
        return accountsResponse;
    }

    public void setAccountsResponse(boolean accountsResponse) {
        this.accountsResponse = accountsResponse;
    }

    public boolean isAccountsSecondResponse() {
        return accountsSecondResponse;
    }

    public void setAccountsSecondResponse(boolean accountsSecondResponse) {
        this.accountsSecondResponse = accountsSecondResponse;
    }

    public boolean getCreditscoreresponse() {
        return cSResponse;
    }

    public void setCreditscoreresponse(boolean creditscoreresponse) {
        this.cSResponse = creditscoreresponse;
    }

    public LoginDTO getLoginPayload() {
        return loginPayload;
    }

    public void setLoginPayload(LoginDTO loginPayload) {
        this.loginPayload = loginPayload;
    }

    public AccountTransferDTO getAccountTransferPayload() {
        return accountTransferPayload;
    }

    public void setAccountTransferPayload(AccountTransferDTO accountTransferPayload) {
        this.accountTransferPayload = accountTransferPayload;
    }

    public Accounts getRequestAccounts() {
        return requestAccounts;
    }

    public void setRequestAccounts(Accounts requestAccounts) {
        this.requestAccounts = requestAccounts;
    }

    public CreditScore getRequestCreditScore() {
        return requestCreditScore;
    }

    public void setRequestCreditScore(CreditScore requestCreditScore) {
        this.requestCreditScore = requestCreditScore;
    }

    private String sagaId;
    private Set<String> replies;
    private boolean accounts;
    private boolean newBA;
    private String accountResponse;

    public String getAccountResponse() {
        return accountResponse;
    }

    public void setAccountResponse(String accountResponse) {
        this.accountResponse = accountResponse;
    }

    public String getcSResponse() {
        return creditscoreresponse;
    }

    public void setcSResponse(String cSResponse) {
        creditscoreresponse = cSResponse;
    }

    private boolean newCC;

    private String creditscoreresponse;

    @Override
    public String toString() {
        try {
            return new ObjectMapper().writeValueAsString(this);
        } catch (JsonProcessingException e) {
            return "";
        }
    }

    private boolean viewAll;
    private boolean viewBA;
    private boolean viewCC;
    private boolean viewCS;
    private boolean accTransfer;
    private boolean newCustomer;
    private boolean invokeError;
    private boolean rollbackPerformed;
    private boolean accountsResponse;
    private boolean accountsSecondResponse;
    private boolean cSResponse;
    private LoginDTO loginPayload;
    private AccountTransferDTO accountTransferPayload;
    private Accounts requestAccounts;
    private CreditScore requestCreditScore;

    public Boolean getDepositResponse() {
        return isDepositResponse;
    }

    public void setDepositResponse(Boolean depositResponse) {
        isDepositResponse = depositResponse;
    }

    public Boolean getWithdrawResponse() {
        return isWithdrawResponse;
    }

    public void setWithdrawResponse(Boolean withdrawResponse) {
        isWithdrawResponse = withdrawResponse;
    }

    private Boolean isDepositResponse;
    private Boolean isWithdrawResponse;

    public CloudBankSagaInfo() {
        replies = new HashSet<>();
    }

    public Set<String> getReplies() {
        return this.replies;
    }

    public void addReply(String participant) {
        replies.add(participant);
    }

    private String fromBank;
    private String toBank;

    public String getFromBank() {
        return fromBank;
    }

    public void setFromBank(String fromBank) {
        this.fromBank = fromBank;
    }

    public String getToBank() {
        return toBank;
    }

    public void setToBank(String toBank) {
        this.toBank = toBank;
    }
}
