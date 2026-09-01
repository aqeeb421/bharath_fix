/**
 * Bharath Fix - Official Marketing Website & Service Portal
 * Fast, lightweight, SEO-optimized interactive logic.
 * Direct WhatsApp & Helpline Booking Engine (No login required for 100% conversion & instant lead generation).
 */

document.addEventListener('DOMContentLoaded', () => {
  // Set default date picker to today
  const modalDate = document.getElementById('modalDate');
  if (modalDate) {
    const today = new Date().toISOString().split('T')[0];
    modalDate.value = today;
    modalDate.min = today;
  }

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

  // Service Pricing Matrix & Estimator Map
  const servicePriceMap = {
    'ac': { name: 'AC Servicing & Repair', startPrice: 19, options: ['Doorstep Visit & Inspection (₹19)', 'Jet Servicing (₹599)', 'Gas Refill (₹1,499)', 'AC Repair & Diagnosis (₹499)', 'Uninstallation / Installation (₹799)'] },
    'washing-machine': { name: 'Washing Machine Repair', startPrice: 19, options: ['Doorstep Visit & Inspection (₹19)', 'Drum/Spin Repair (₹499)', 'PCB Repair (₹899)', 'Water Inlet Fix (₹299)'] },
    'refrigerator': { name: 'Refrigerator / Fridge Repair', startPrice: 19, options: ['Doorstep Visit & Inspection (₹19)', 'Gas Charging (₹1,299)', 'Compressor Fix (₹1,599)', 'Thermostat/Relay (₹399)'] },
    'water-purifier': { name: 'Water Purifier / RO Service', startPrice: 19, options: ['Doorstep Visit & Inspection (₹19)', 'RO Full Filter Service (₹499)', 'Membrane Replacement (₹899)', 'UV/UF Lamp Fix (₹399)', 'Leakage Repair (₹299)'] },
    'water-heater': { name: 'Water Heater / Geyser Repair', startPrice: 19, options: ['Doorstep Visit & Inspection (₹19)', 'Heating Element Change (₹599)', 'Tank Descaling (₹499)', 'Geyser Installation (₹399)'] },
    'microwave': { name: 'Microwave Oven Repair', startPrice: 19, options: ['Doorstep Visit & Inspection (₹19)', 'Magnetron Fix (₹699)', 'Touchpanel / PCB Fix (₹799)', 'Fuse & Wiring Fix (₹299)'] },
    'chimney': { name: 'Kitchen Chimney Service', startPrice: 19, options: ['Doorstep Visit & Inspection (₹19)', 'Deep Degreasing Service (₹699)', 'Motor & Fan Repair (₹599)', 'Duct Pipe Installation (₹499)'] },
    'air-cooler': { name: 'Air Cooler Servicing', startPrice: 19, options: ['Doorstep Visit & Inspection (₹19)', 'Pump Replacement (₹399)', 'Cooling Pad Change (₹299)', 'Motor Repair (₹499)'] }
  };

  // Service Booking Modal Controls
  const modalOverlay = document.getElementById('bookingModal');
  const modalCloseBtn = document.getElementById('modalClose');
  const modalServiceSelect = document.getElementById('modalService');

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
      if (e.target === modalOverlay) closeBookingModal();
    });
  }

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
      option.textContent = 'General Repair & Inspection (₹19)';
      subOptionSelect.appendChild(option);
    }
  }

  if (modalServiceSelect) {
    modalServiceSelect.addEventListener('change', (e) => {
      updateModalOptions(e.target.value);
    });
  }

  // Handle Quick Hero Booking Form Submission
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
        category: servicePriceMap[service]?.name || service,
        phone: phone,
        pincode: pincode,
        notes: 'Quick Service Request from Hero Banner'
      });
    });
  }

  // Handle Service Modal Form Submission
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
        category: servicePriceMap[serviceKey]?.name || serviceKey,
        subOption: subOption,
        name: name,
        phone: phone,
        address: address,
        date: preferredDate
      });

      closeBookingModal();
    });
  }

  // Helper Function: Dispatch Instant WhatsApp Booking Message
  function sendWhatsAppBooking(data) {
    const phoneNumber = '919148699386'; // Official BharathFix Helpline
    let text = `*NEW BOOKING REQUEST - BHARATH FIX WEBSITE*\n\n`;
    text += `🛠️ *Service*: ${data.category}\n`;
    if (data.subOption) text += `📌 *Option*: ${data.subOption}\n`;
    if (data.name) text += `👤 *Customer Name*: ${data.name}\n`;
    text += `📞 *Phone*: ${data.phone}\n`;
    if (data.pincode) text += `📍 *Pincode*: ${data.pincode}\n`;
    if (data.address) text += `🏠 *Address*: ${data.address}\n`;
    if (data.date) text += `📅 *Preferred Date*: ${data.date}\n`;
    text += `\nPlease confirm technician assignment & slot availability!`;

    const encodedText = encodeURIComponent(text);
    const whatsappUrl = `https://wa.me/${phoneNumber}?text=${encodedText}`;
    window.open(whatsappUrl, '_blank');
  }

  // ==========================================
  // Appliance Sales Store Modal & Order Handler
  // ==========================================
  const salesModal = document.getElementById('salesModal');
  window.openSalesModal = function(productId, productName, category, price) {
    if (salesModal) {
      document.getElementById('salesProductId').value = productId;
      document.getElementById('salesProductName').value = productName;
      document.getElementById('salesProductCategory').value = category;
      document.getElementById('salesProductPrice').value = price;

      document.getElementById('salesModalTitle').textContent = `Order ${productName}`;
      document.getElementById('salesModalPriceTag').textContent = `Price: ₹${price.toLocaleString()} • 6 Months Warranty`;

      salesModal.classList.add('active');
    }
  };

  window.closeSalesModal = function() {
    if (salesModal) salesModal.classList.remove('active');
  };

  if (salesModal) {
    salesModal.addEventListener('click', (e) => {
      if (e.target === salesModal) closeSalesModal();
    });
  }

  const salesForm = document.getElementById('salesOrderForm');
  if (salesForm) {
    salesForm.addEventListener('submit', (e) => {
      e.preventDefault();
      const productName = document.getElementById('salesProductName').value;
      const price = document.getElementById('salesProductPrice').value;

      const name = document.getElementById('salesName').value;
      const phone = document.getElementById('salesPhone').value;
      const address = document.getElementById('salesAddress').value;
      const pincode = document.getElementById('salesPincode').value;

      if (!phone || phone.length < 10) {
        alert('Please enter a valid 10-digit mobile number.');
        return;
      }

      closeSalesModal();

      // Dispatch direct WhatsApp order inquiry
      const text = `*NEW APPLIANCE STORE ORDER - BHARATH FIX*\n\n🛒 *Product*: ${productName}\n💰 *Offer Price*: ₹${price}\n👤 *Customer*: ${name}\n📞 *Phone*: ${phone}\n🏠 *Address*: ${address}\n📍 *Pincode*: ${pincode}\n\nPlease confirm availability, delivery slot, and free installation!`;
      window.open(`https://wa.me/919148699386?text=${encodeURIComponent(text)}`, '_blank');
    });
  }
});
