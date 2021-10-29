package com.ClassicQueue.DTO;

import java.io.Serializable;


	public class UserDetails implements Serializable {

		private static final long serialVersionUID = 1L;

		private int orderId;
		
		private String username;
		
		private int otp;
		
		private String deliveryStatus;
		
		private String deliveryLocation;
	
		public UserDetails() {
	
		}
	
		public UserDetails(int orderId, String username, int otp, String deliveryStatus, String deliveryLocation) {
			super();
			this.orderId = orderId;
			this.username = username;
			this.otp = otp;
			this.deliveryStatus = deliveryStatus;
			this.deliveryLocation = deliveryLocation;
		}

		public int getOrderId() {
			return orderId;
		}

		public void setOrderId(int orderId) {
			this.orderId = orderId;
		}

		public String getUsername() {
			return username;
		}

		public void setUsername(String username) {
			this.username = username;
		}

		public int getOtp() {
			return otp;
		}

		public void setOtp(int otp) {
			this.otp = otp;
		}

		public String getDeliveryStatus() {
			return deliveryStatus;
		}

		public void setDeliveryStatus(String deliveryStatus) {
			this.deliveryStatus = deliveryStatus;
		}

		public String getDeliveryLocation() {
			return deliveryLocation;
		}

		public void setDeliveryLocation(String deliveryLocation) {
			this.deliveryLocation = deliveryLocation;
		}


}
