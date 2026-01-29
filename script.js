// Contact Form Handling
document.getElementById('contactForm').addEventListener('submit', function(e) {
    e.preventDefault();
    
    // Get form data
    const formData = {
        firstName: document.getElementById('firstName').value,
        lastName: document.getElementById('lastName').value,
        email: document.getElementById('email').value,
        phone: document.getElementById('phone').value,
        company: document.getElementById('company').value,
        message: document.getElementById('message').value,
        timestamp: new Date().toISOString()
    };
    
    // Show loading state
    const submitButton = e.target.querySelector('.submit-button');
    const originalText = submitButton.textContent;
    submitButton.textContent = 'Submitting...';
    submitButton.disabled = true;
    
    // Submit to backend API
    // TODO: Replace YOUR-BACKEND-URL with your actual backend URL
    // Options:
    // 1. EC2: http://your-ec2-ip/api/contact
    // 2. Elastic Beanstalk: https://your-app.elasticbeanstalk.com/api/contact
    // 3. API Gateway: https://your-api-id.execute-api.region.amazonaws.com/prod/api/contact
    const apiUrl = window.location.hostname === 'localhost' 
        ? 'http://localhost:3000/api/contact'
        : 'https://autoreportform.click/api/contact';
    
    fetch(apiUrl, {
        method: 'POST',
        headers: {
            'Content-Type': 'application/json',
        },
        body: JSON.stringify(formData)
    })
    .then(response => response.json())
    .then(data => {
        const messageDiv = document.getElementById('formMessage');
        
        if (data.success) {
            messageDiv.className = 'form-message success';
            messageDiv.textContent = 'Thank you! Your information has been submitted successfully. We will contact you soon.';
            document.getElementById('contactForm').reset();
        } else {
            messageDiv.className = 'form-message error';
            messageDiv.textContent = data.error || 'Sorry, there was an error submitting the form. Please try again.';
        }
        
        // Reset button
        submitButton.textContent = originalText;
        submitButton.disabled = false;
        
        // Hide message after 5 seconds
        setTimeout(() => {
            messageDiv.style.display = 'none';
        }, 5000);
    })
    .catch(error => {
        console.error('Error:', error);
        const messageDiv = document.getElementById('formMessage');
        messageDiv.className = 'form-message error';
        messageDiv.textContent = 'Sorry, there was an error submitting the form. Please try again.';
        submitButton.textContent = originalText;
        submitButton.disabled = false;
    });
    
    /* 
    EXAMPLE AWS INTEGRATION (uncomment and configure):
    
    fetch('https://YOUR-API-GATEWAY-URL.amazonaws.com/prod/contact', {
        method: 'POST',
        headers: {
            'Content-Type': 'application/json',
        },
        body: JSON.stringify(formData)
    })
    .then(response => response.json())
    .then(data => {
        const messageDiv = document.getElementById('formMessage');
        messageDiv.className = 'form-message success';
        messageDiv.textContent = 'Thank you! Your information has been submitted successfully.';
        document.getElementById('contactForm').reset();
        submitButton.textContent = originalText;
        submitButton.disabled = false;
    })
    .catch(error => {
        const messageDiv = document.getElementById('formMessage');
        messageDiv.className = 'form-message error';
        messageDiv.textContent = 'Sorry, there was an error submitting the form. Please try again.';
        submitButton.textContent = originalText;
        submitButton.disabled = false;
    });
    */
});

// Smooth scrolling for navigation links
document.querySelectorAll('a[href^="#"]').forEach(anchor => {
    anchor.addEventListener('click', function (e) {
        e.preventDefault();
        const target = document.querySelector(this.getAttribute('href'));
        if (target) {
            target.scrollIntoView({
                behavior: 'smooth',
                block: 'start'
            });
        }
    });
});
