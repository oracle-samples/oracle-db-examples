/*
 * Copyright (c) 2026 Oracle and/or its affiliates.
 *
 * Licensed under the Universal Permissive License v 1.0 as shown at
 * https://oss.oracle.com/licenses/upl/
 */

package com.foobar.instance.service;

import com.foobar.instance.domain.MetaData;
import com.foobar.instance.repo.ReadMetaDataDAO;
import com.foobar.instance.repo.WriteMetaDataDAO;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

@Service
public class MetaDataService {

    @Autowired
    ReadMetaDataDAO readMetaDataDAO;

    @Autowired
    WriteMetaDataDAO writeMetaDataDAO;

    @Transactional(readOnly = true, transactionManager = "readTransactionManager")
    public MetaData getInstance(String country) {
        return readMetaDataDAO.getInstance(country);
    }

    @Transactional(transactionManager = "writeTransactionManager")
    public MetaData postInstance(String county) {
        return writeMetaDataDAO.postInstance(county);
    }
}
