package com.gautam.billingsoftware.service;

import com.razorpay.RazorpayException;
import com.gautam.billingsoftware.io.RazorpayOrderResponse;

public interface RazorpayService {

    RazorpayOrderResponse createOrder(Double amount, String currency) throws RazorpayException;
}
