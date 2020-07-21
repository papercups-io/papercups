import Alert from 'antd/lib/alert';
import Badge from 'antd/lib/badge';
import Button from 'antd/lib/button';
import DatePicker from 'antd/lib/date-picker';
import Dropdown from 'antd/lib/dropdown';
import Input from 'antd/lib/input';
import Layout from 'antd/lib/layout';
import Menu from 'antd/lib/menu';
import Modal from 'antd/lib/modal';
import notification from 'antd/lib/notification';
import Popconfirm from 'antd/lib/popconfirm';
import Popover from 'antd/lib/popover';
import Radio from 'antd/lib/radio';
import Result from 'antd/lib/result';
import Select from 'antd/lib/select';
import Spin from 'antd/lib/spin';
import Table from 'antd/lib/table';
import Tag from 'antd/lib/tag';
import Tooltip from 'antd/lib/tooltip';
import Typography from 'antd/lib/typography';

import {blue, green, red, gold, grey} from '@ant-design/colors';

const {Title, Text, Paragraph} = Typography;
const {Header, Content, Footer, Sider} = Layout;

export const colors = {
  white: '#fff',
  black: '#000',
  primary: blue[5],
  green: green[5],
  red: red[5],
  gold: gold[5],
  blue: blue, // expose all blues
  gray: grey, // expose all grays
};

export const TextArea = Input.TextArea;

export {
  // Typography
  Title,
  Text,
  Paragraph,
  // Layout
  Content,
  Footer,
  Layout,
  Header,
  Sider,
  // Components
  Alert,
  Badge,
  Button,
  DatePicker,
  Dropdown,
  Input,
  Menu,
  Modal,
  notification,
  Popconfirm,
  Popover,
  Radio,
  Result,
  Select,
  Spin,
  Table,
  Tag,
  Tooltip,
};
