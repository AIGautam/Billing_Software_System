package com.gautam.billingsoftware.controller;

import com.razorpay.RazorpayException;
import com.gautam.billingsoftware.io.OrderResponse;
import com.gautam.billingsoftware.io.PaymentRequest;
import com.gautam.billingsoftware.io.PaymentVerificationRequest;
import com.gautam.billingsoftware.io.RazorpayOrderResponse;
import com.gautam.billingsoftware.service.OrderService;
import com.gautam.billingsoftware.service.RazorpayService;
import lombok.RequiredArgsConstructor;
import org.springframework.http.HttpStatus;
import org.springframework.web.bind.annotation.*;

@RestController
@RequestMapping("/payments")
@RequiredArgsConstructor
public class PaymentController {

    private final RazorpayService razorpayService;
    private final OrderService orderService;

    @PostMapping("/create-order")
    @ResponseStatus(HttpStatus.CREATED)
    public RazorpayOrderResponse createRazorpayOrder(@RequestBody PaymentRequest request) throws RazorpayException {
        return razorpayService.createOrder(request.getAmount(), request.getCurrency());
    }

    @PostMapping("/verify")
    public OrderResponse verifyPayment(@RequestBody PaymentVerificationRequest request) {
        return orderService.verifyPayment(request);
    }
}
