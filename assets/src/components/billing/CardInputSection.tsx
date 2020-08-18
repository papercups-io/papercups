import React from 'react';
import {CardElement} from '@stripe/react-stripe-js';
import {colors} from '../common';
import './StripeElement.css';

const CARD_ELEMENT_OPTIONS = {
  style: {
    base: {
      color: 'rgba(0, 0, 0, 0.65)',
      fontFamily: "'Open Sans', 'Helvetica Neue', Arial, san-serif",
      fontSmoothing: 'antialiased',
      fontSize: '14px',
      '::placeholder': {
        color: 'rgba(0, 0, 0, 0.4)',
      },
    },
    invalid: {
      color: colors.red,
      iconColor: colors.red,
    },
  },
};

const CardInputSection = () => {
  return <CardElement options={CARD_ELEMENT_OPTIONS} />;
};

export default CardInputSection;
