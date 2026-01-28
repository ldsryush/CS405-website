// Contact Form Submission Handler
document.addEventListener('DOMContentLoaded', function() {
    const contactForm = document.getElementById('contactForm');
    const formMessage = document.getElementById('formMessage');
    
    // Check if required elements exist
    if (!contactForm || !formMessage) {
        console.error('Required form elements not found');
        return;
    }
    
    contactForm.addEventListener('submit', function(e) {
        e.preventDefault();
        
        // Get form values
        const formData = {
            name: document.getElementById('name').value,
            email: document.getElementById('email').value,
            phone: document.getElementById('phone').value,
            company: document.getElementById('company').value,
            message: document.getElementById('message').value
        };
        
        // Simulate form submission (in a real application, this would send data to a server)
        console.log('Form submitted with data:', formData);
        
        // Show success message
        formMessage.className = 'form-message success show';
        formMessage.textContent = 'Thank you for your message! We will get back to you shortly.';
        
        // Reset form and validation classes
        contactForm.reset();
        const inputs = contactForm.querySelectorAll('input, textarea');
        inputs.forEach(input => {
            input.classList.remove('valid', 'invalid');
        });
        
        // Hide message after 5 seconds
        setTimeout(function() {
            formMessage.classList.remove('show');
        }, 5000);
    });
    
    // Add input validation feedback
    const inputs = contactForm.querySelectorAll('input[required], textarea[required]');
    inputs.forEach(input => {
        input.addEventListener('blur', function() {
            if (this.value.trim() === '') {
                this.classList.add('invalid');
                this.classList.remove('valid');
            } else if (this.validity && this.validity.valid) {
                this.classList.add('valid');
                this.classList.remove('invalid');
            }
        });
        
        input.addEventListener('input', function() {
            if (this.value.trim() !== '') {
                this.classList.remove('invalid', 'valid');
            }
        });
    });
});
