/**
 * Bharath Fix - Official Marketing Website JavaScript Logic
 * Handles interactive elements, price calculations, booking modal, and WhatsApp integration.
 */

document.addEventListener('DOMContentLoaded', () => {
  // Mobile Navigation Drawer Toggle
  const mobileToggle = document.getElementById('mobileToggle');
  const navMenu = document.getElementById('navMenu');

  if (mobileToggle && navMenu) {
    mobileToggle.addEventListener('click', () => {
      navMenu.classList.toggle('active');
      const icon = mobileToggle.querySelector('i');
      if (icon) {
        icon.classList.toggle('fa-bars');
        icon.classList.toggle('fa-xmark');
      }
    });

    // Close menu when clicking nav link
    document.querySelectorAll('.nav-link').forEach(link => {
      link.addEventListener('click', () => {
        navMenu.classList.remove('active');
        const icon = mobileToggle.querySelector('i');
        if (icon) {
          icon.classList.add('fa-bars');
          icon.classList.remove('fa-xmark');
        }
      });
    });
  }

  // FAQ Accordion Interactivity
  const faqItems = document.querySelectorAll('.faq-item');
  faqItems.forEach(item => {
    const question = item.querySelector('.faq-question');
    if (question) {
      question.addEventListener('click', () => {
        const isOpen = item.classList.contains('active');
        faqItems.forEach(i => i.classList.remove('active'));
        if (!isOpen) {
          item.classList.add('active');
        }
      });
    }
  });

  // Service Pricing Matrix & Estimator Logic
  const servicePriceMap = {
    'ac': { name: 'AC Servicing & Repair', startPrice: 499, options: ['Jet Servicing (₹599)', 'Gas Refill (₹1,499)', 'AC Repair & Diagnosis (₹499)', 'Uninstallation / Installation (₹799)'] },
    'washing-machine': { name: 'Washing Machine Repair', startPrice: 199, options: ['General Checkup (₹199)', 'Drum/Spin Repair (₹499)', 'PCB Repair (₹899)', 'Water Inlet Fix (₹299)'] },
    'refrigerator': { name: 'Refrigerator / Fridge Repair', startPrice: 199, options: ['Inspection & Service (₹199)', 'Gas Charging (₹1,299)', 'Compressor Fix (₹1,599)', 'Thermostat/Relay (₹399)'] },
    'water-purifier': { name: 'Water Purifier / RO Service', startPrice: 299, options: ['RO Full Filter Service (₹499)', 'Membrane Replacement (₹899)', 'UV/UF Lamp Fix (₹399)', 'Leakage Repair (₹299)'] },
    'water-heater': { name: 'Water Heater / Geyser Repair', startPrice: 249, options: ['Thermostat Check (₹249)', 'Heating Element Change (₹599)', 'Tank Descaling (₹499)', 'Geyser Installation (₹399)'] },
    'microwave': { name: 'Microwave Oven Repair', startPrice: 299, options: ['Magnetron Fix (₹699)', 'Touchpanel / PCB Fix (₹799)', 'Fuse & Wiring Fix (₹299)', 'General Service (₹299)'] },
    'chimney': { name: 'Kitchen Chimney Service', startPrice: 399, options: ['Deep Degreasing Service (₹699)', 'Motor & Fan Repair (₹599)', 'Duct Pipe Installation (₹499)', 'General Cleaning (₹399)'] },
    'air-cooler': { name: 'Air Cooler Servicing', startPrice: 199, options: ['Pump Replacement (₹399)', 'Cooling Pad Change (₹299)', 'Motor Repair (₹499)', 'Full Cleaning (₹199)'] }
  };

  // Booking Modal Logic
  const modalOverlay = document.getElementById('bookingModal');
  const modalCloseBtn = document.getElementById('modalClose');
  const modalServiceSelect = document.getElementById('modalService');

  // Function to open modal with specific service selected
  window.openBookingModal = function(serviceKey) {
    if (modalOverlay) {
      if (serviceKey && modalServiceSelect) {
        modalServiceSelect.value = serviceKey;
        updateModalOptions(serviceKey);
      }
      modalOverlay.classList.add('active');
    }
  };

  window.closeBookingModal = function() {
    if (modalOverlay) {
      modalOverlay.classList.remove('active');
    }
  };

  if (modalCloseBtn) {
    modalCloseBtn.addEventListener('click', closeBookingModal);
  }

  if (modalOverlay) {
    modalOverlay.addEventListener('click', (e) => {
      if (e.target === modalOverlay) {
        closeBookingModal();
      }
    });
  }

  // Update Modal Sub-service options
  function updateModalOptions(serviceKey) {
    const subOptionSelect = document.getElementById('modalSubOption');
    if (!subOptionSelect) return;

    subOptionSelect.innerHTML = '';
    const serviceInfo = servicePriceMap[serviceKey];
    if (serviceInfo && serviceInfo.options) {
      serviceInfo.options.forEach(opt => {
        const option = document.createElement('option');
        option.value = opt;
        option.textContent = opt;
        subOptionSelect.appendChild(option);
      });
    } else {
      const option = document.createElement('option');
      option.value = 'General Repair & Inspection';
      option.textContent = 'General Repair & Inspection (₹199)';
      subOptionSelect.appendChild(option);
    }
  }

  if (modalServiceSelect) {
    modalServiceSelect.addEventListener('change', (e) => {
      updateModalOptions(e.target.value);
    });
  }

  // Handle Quick Form Submission (Hero Section Form)
  const heroForm = document.getElementById('quickBookingForm');
  if (heroForm) {
    heroForm.addEventListener('submit', (e) => {
      e.preventDefault();
      const service = document.getElementById('heroService').value;
      const phone = document.getElementById('heroPhone').value;
      const pincode = document.getElementById('heroPincode').value;

      if (!phone || phone.length < 10) {
        alert('Please enter a valid 10-digit mobile number.');
        return;
      }

      sendWhatsAppBooking({
        service: servicePriceMap[service]?.name || service,
        phone: phone,
        pincode: pincode,
        notes: 'Quick Home Service Request from Website Hero Banner'
      });
    });
  }

  // Handle Modal Form Submission
  const modalForm = document.getElementById('modalBookingForm');
  if (modalForm) {
    modalForm.addEventListener('submit', (e) => {
      e.preventDefault();
      const serviceKey = document.getElementById('modalService').value;
      const subOption = document.getElementById('modalSubOption').value;
      const name = document.getElementById('modalName').value;
      const phone = document.getElementById('modalPhone').value;
      const address = document.getElementById('modalAddress').value;
      const preferredDate = document.getElementById('modalDate').value;

      if (!phone || phone.length < 10) {
        alert('Please enter a valid 10-digit mobile number.');
        return;
      }

      sendWhatsAppBooking({
        service: `${servicePriceMap[serviceKey]?.name || serviceKey} (${subOption})`,
        name: name,
        phone: phone,
        address: address,
        date: preferredDate,
        notes: 'Full Service Booking Request from Modal'
      });

      closeBookingModal();
    });
  }

  // Helper Function: Send Direct WhatsApp Message & Trigger Call Option
  function sendWhatsAppBooking(data) {
    const phoneNumber = '919148699386'; // Official Helpline
    let text = `*NEW BOOKING REQUEST - BHARATH FIX*\n\n`;
    text += `🛠️ *Service*: ${data.service}\n`;
    if (data.name) text += `👤 *Customer Name*: ${data.name}\n`;
    text += `📞 *Phone*: ${data.phone}\n`;
    if (data.pincode) text += `📍 *Pincode*: ${data.pincode}\n`;
    if (data.address) text += `🏠 *Address*: ${data.address}\n`;
    if (data.date) text += `📅 *Preferred Date*: ${data.date}\n`;
    text += `\nPlease confirm technician assignment and arrival time!`;

    const encodedText = encodeURIComponent(text);
    const whatsappUrl = `https://wa.me/${phoneNumber}?text=${encodedText}`;

    // Open WhatsApp in a new tab
    window.open(whatsappUrl, '_blank');
  }
});
