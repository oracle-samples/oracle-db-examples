/*
 * Copyright (c) 2018 Oracle and/or its affiliates. All rights reserved.
 *
 * Licensed under the Apache License, Version 2.0 (the "License");
 * you may not use this file except in compliance with the License.
 * You may obtain a copy of the License at
 *
 *      http://www.apache.org/licenses/LICENSE-2.0
 *
 * Unless required by applicable law or agreed to in writing, software
 * distributed under the License is distributed on an "AS IS" BASIS,
 * WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
 * See the License for the specific language governing permissions and
 * limitations under the License.
 */
package com.oracle.adbaoverjdbc;

import java.util.concurrent.CompletableFuture;
import java.util.concurrent.CompletionStage;
import java.util.function.Supplier;

/**
 *
 */
class Submission<T> implements jdk.incubator.sql2.Submission<T> {

  final private Supplier<Boolean> cancel;
  final private CompletionStage<T> stage;
  private CompletionStage<T> publicStage;
  
  static <T> Submission<T> submit(Supplier<Boolean> cancel, CompletionStage<T> s) {
    return new Submission<>(cancel, s);
  }
  
  protected Submission(Supplier<Boolean> can, CompletionStage<T> stg) {
    cancel = can;
    stage = stg;
  }
  
  @Override
  public CompletionStage<Boolean> cancel() {
    return new CompletableFuture().completeAsync(cancel);
  }

  @Override
  public CompletionStage<T> getCompletionStage() {
    if (publicStage == null) publicStage = ((CompletableFuture)stage).minimalCompletionStage();
    return publicStage;
  }
  
}
