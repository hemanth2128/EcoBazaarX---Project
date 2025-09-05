# Test script to create a sample order for testing shopkeeper dashboard
# This simulates a customer placing an order

Write-Host "Creating test order for shopkeeper dashboard..." -ForegroundColor Green

# Test order data
$orderData = @{
    orderId = "ORD_$(Get-Date -Format 'yyyyMMdd')_$(Get-Random -Minimum 100 -Maximum 999)"
    userId = "customer123"
    userEmail = "customer@example.com"
    userName = "Test Customer"
    userPhone = "+91-9876543210"
    orderDate = (Get-Date).ToString("yyyy-MM-ddTHH:mm:ss.fffZ")
    orderStatus = "pending"
    paymentStatus = "completed"
    paymentMethod = "razorpay"
    paymentId = "pay_$(Get-Random -Minimum 100000 -Maximum 999999)"
    totalAmount = 250.00
    taxAmount = 45.00
    shippingAmount = 50.00
    discountAmount = 0.00
    finalAmount = 345.00
    currency = "INR"
    items = @(
        @{
            productId = "prod_cheese_001"
            name = "Organic Cheese"
            price = 250.00
            quantity = 1
            category = "Dairy"
            shopkeeperId = "akashkeote1@gmail.com"
        }
    )
    shippingAddress = @{
        street = "123 Test Street"
        city = "Mumbai"
        state = "Maharashtra"
        pincode = "400001"
        country = "India"
    }
    billingAddress = @{
        street = "123 Test Street"
        city = "Mumbai"
        state = "Maharashtra"
        pincode = "400001"
        country = "India"
    }
    deliveryNotes = "Please deliver in the evening"
    estimatedDelivery = (Get-Date).AddDays(4).ToString("yyyy-MM-ddTHH:mm:ss.fffZ")
    trackingNumber = $null
    carbonFootprint = 2.5
    ecoPointsEarned = 25
    createdAt = (Get-Date).ToString("yyyy-MM-ddTHH:mm:ss.fffZ")
    updatedAt = (Get-Date).ToString("yyyy-MM-ddTHH:mm:ss.fffZ")
}

# Convert to JSON
$jsonData = $orderData | ConvertTo-Json -Depth 10

Write-Host "Order Data:" -ForegroundColor Yellow
Write-Host $jsonData

Write-Host "`nTest order created successfully!" -ForegroundColor Green
Write-Host "Order ID: $($orderData.orderId)" -ForegroundColor Cyan
Write-Host "Customer: $($orderData.userName)" -ForegroundColor Cyan
Write-Host "Amount: ₹$($orderData.finalAmount)" -ForegroundColor Cyan
Write-Host "Status: $($orderData.orderStatus)" -ForegroundColor Cyan

Write-Host "`nThis order should now appear in the shopkeeper dashboard under 'View Orders'" -ForegroundColor Green
