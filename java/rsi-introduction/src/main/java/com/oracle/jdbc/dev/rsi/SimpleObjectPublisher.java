/*
  Copyright (c) 2021, 2022, Oracle and/or its affiliates.

  This software is dual-licensed to you under the Universal Permissive License
  (UPL) 1.0 as shown at https://oss.oracle.com/licenses/upl or Apache License
  2.0 as shown at http://www.apache.org/licenses/LICENSE-2.0. You may choose
  either license.

  Licensed under the Apache License, Version 2.0 (the "License");
  you may not use this file except in compliance with the License.
  You may obtain a copy of the License at

     https://www.apache.org/licenses/LICENSE-2.0

  Unless required by applicable law or agreed to in writing, software
  distributed under the License is distributed on an "AS IS" BASIS,
  WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
  See the License for the specific language governing permissions and
  limitations under the License.
*/

package com.oracle.jdbc.dev.rsi;

import java.util.concurrent.Flow.Publisher;
import java.util.concurrent.Flow.Subscriber;
import java.util.concurrent.Flow.Subscription;
import java.util.function.Consumer;

public class SimpleObjectPublisher<T> implements Publisher<T>, Consumer<T> {

	  Subscriber<? super T> subscriber;
	  
	  Subscription subscription = new SimpleObjectSubscription(); 
	 
	 //Data streaming starts

	  @Override
	  public void subscribe(Subscriber<? super T> subscriber) {
	    this.subscriber = subscriber;
	    this.subscriber.onSubscribe(subscription);
	  }
	  
	  @Override
	  public void accept(T t) {
	    subscriber.onNext(t);
	  }
	  
	}