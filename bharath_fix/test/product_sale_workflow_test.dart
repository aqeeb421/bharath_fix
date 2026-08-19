import 'package:flutter_test/flutter_test.dart';
import 'package:bharath_fix/models/ProductSaleModel.dart';
import 'package:bharath_fix/models/AddressModel.dart';
import 'package:bharath_fix/models/UserModel.dart';
import 'package:bharath_fix/services/coupon_service.dart';

void main() {
  group('Customer App Product Sales Feature & Workflow Tests', () {
    test('1. ProductSaleModel Serialization & Deserialization with Specs', () {
      final sampleProductMap = {
        'id': 'prod_ro_101',
        'name': 'BharathFix Smart Copper RO Water Purifier',
        'subCategory': 'Water Purifier',
        'price': '₹6,999',
        'image': 'https://example.com/ro_purifier.jpg',
        'description': 'Pure mineral-infused drinking water for Indian homes.',
        'specifications': {
          'Purification Flow': 'RO + UV + Copper + Minerals',
          'Capacity': '8 Liters clear tank',
          'Warranty': '1 Year Comprehensive',
        },
        'stockQuantity': 15,
        'originalPrice': '₹12,999',
        'discountPercentage': 46,
        'warrantyPeriod': '1 Year Comprehensive Warranty',
        'deliveryDays': 2,
      };

      final product = ProductSaleModel.fromMap(sampleProductMap);

      expect(product.id, equals('prod_ro_101'));
      expect(product.name, contains('Smart Copper RO'));
      expect(product.stockQuantity, equals(15));
      expect(product.discountPercentage, equals(46));
      expect(product.specifications['Purification Flow'], equals('RO + UV + Copper + Minerals'));

      final serializedMap = product.toMap();
      expect(serializedMap['id'], equals('prod_ro_101'));
      expect(serializedMap['stockQuantity'], equals(15));
    });

    test('2. Tax & Base Price Calculation Logic (18% IGST)', () {
      const priceString = '₹11,800';
      final cleanPrice = priceString.replaceAll('₹', '').replaceAll(',', '').trim();
      final totalPayable = double.parse(cleanPrice);

      final basePrice = totalPayable / 1.18;
      final gstAmount = totalPayable - basePrice;

      expect(totalPayable, equals(11800.0));
      expect(basePrice, equals(10000.0));
      expect(gstAmount, equals(1800.0));
    });

    test('3. Coupon Service Discount Application on Product Purchase', () async {
      final couponService = CouponService();

      // Test FIRST50 coupon on ₹6,999 product (50% max capped at ₹150)
      final result1 = await couponService.validateAndApplyCoupon('FIRST50', 6999.0);
      expect(result1['success'], isTrue);
      expect(result1['discountAmount'], equals(150.0));
      expect(result1['finalTotal'], equals(6849.0));

      // Test WELCOME50 coupon on ₹5,000 product (50% max capped at ₹200)
      final result2 = await couponService.validateAndApplyCoupon('WELCOME50', 5000.0);
      expect(result2['success'], isTrue);
      expect(result2['discountAmount'], equals(200.0));
      expect(result2['finalTotal'], equals(4800.0));
    });

    test('4. Coupon Minimum Order Value Guard Condition', () async {
      final couponService = CouponService();

      // FIXFIRST requires minimum order of ₹299
      final result = await couponService.validateAndApplyCoupon('FIXFIRST', 100.0);
      expect(result['success'], isFalse);
      expect(result['message'], contains('Minimum order amount'));
    });

    test('5. Stock Guard Condition Check', () {
      final inStockProduct = const ProductSaleModel(
        id: 'p1',
        name: 'In Stock AC',
        subCategory: 'AC',
        price: '₹25,000',
        image: '',
        stockQuantity: 5,
      );

      final outOfStockProduct = const ProductSaleModel(
        id: 'p2',
        name: 'Sold Out Fridge',
        subCategory: 'Refrigerator',
        price: '₹18,000',
        image: '',
        stockQuantity: 0,
      );

      expect(inStockProduct.stockQuantity > 0, isTrue);
      expect(outOfStockProduct.stockQuantity > 0, isFalse);
    });

    test('6. AddressModel Serialization & Dynamic Fallback Parsing', () {
      final mapData = {
        'id': 'addr_101',
        'tag': 'Home',
        'house': 'Flat 302',
        'street': 'MG Road',
        'pincode': '573201',
        'isDefault': true,
      };

      final address = AddressModel.fromMap(mapData);

      expect(address.id, equals('addr_101'));
      expect(address.tag, equals('Home'));
      expect(address.details, equals('Flat 302, MG Road, 573201'));
      expect(address.isDefault, isTrue);

      final serialized = address.toMap();
      expect(serialized['id'], equals('addr_101'));
      expect(serialized['details'], equals('Flat 302, MG Road, 573201'));
    });

    test('7. UserModel Firestore Address Parsing (Array, Map & defaultAddress)', () {
      final firestoreUserData = {
        'uid': 'user_999',
        'name': 'Bharath Customer',
        'phone': '+919876543210',
        'email': 'customer@bharathfix.com',
        'address': 'MG Road, Hassan 573201',
        'addresses': [
          {
            'id': 'addr_home',
            'tag': 'Home',
            'details': 'Flat 101, Star Heights, Hassan 573201',
            'isDefault': true,
          },
          {
            'id': 'addr_office',
            'tag': 'Office',
            'details': 'Tech Park, Sector 4, Hassan 573201',
          },
        ],
      };

      final user = UserModel.fromMap(firestoreUserData);

      expect(user.uid, equals('user_999'));
      expect(user.addresses.length, greaterThanOrEqualTo(2));
      expect(user.addresses.any((a) => a.tag == 'Home'), isTrue);
      expect(user.addresses.any((a) => a.tag == 'Office'), isTrue);
      expect(user.defaultAddress, contains('Star Heights'));
    });
  });
}
