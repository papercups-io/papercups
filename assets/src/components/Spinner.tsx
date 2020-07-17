import React from 'react';
import {Spin} from './common';
import {LoadingOutlined} from './icons';

export const Spinner = ({size}: {size: number}) => {
  return (
    <Spin indicator={<LoadingOutlined style={{fontSize: size || 24}} spin />} />
  );
};

export default Spinner;
