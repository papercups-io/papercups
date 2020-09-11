import React from 'react';
import {
  BrowserRouter as Router,
  Switch,
  Route,
  Redirect,
} from 'react-router-dom';
import {useAuth} from './components/auth/AuthProvider';
import Login from './components/auth/Login';
import Register from './components/auth/Register';
import EmailVerification from './components/auth/EmailVerification';
import PasswordReset from './components/auth/PasswordReset';
import RequestPasswordReset from './components/auth/RequestPasswordReset';
import PasswordResetRequested from './components/auth/PasswordResetRequested';
import Demo from './components/demo/Demo';
import Dashboard from './components/Dashboard';
import Pricing from './components/billing/PricingOverview';
import './App.css';

const App = () => {
  const auth = useAuth();

  if (auth.loading) {
    return null; // FIXME: show loading icon
  }

  if (!auth.isAuthenticated) {
    // Public routes
    return (
      <Router>
        <Switch>
          <Route path="/demo" component={Demo} />
          <Route path="/login" component={Login} />
          <Route path="/register/:invite" component={Register} />
          <Route path="/register" component={Register} />
          <Route path="/verify" component={EmailVerification} />
          <Route path="/reset-password" component={RequestPasswordReset} />
          <Route path="/reset" component={PasswordReset} />
          <Route
            path="/reset-password-requested"
            component={PasswordResetRequested}
          />
          <Route path="/pricing" component={Pricing} />
          <Route path="*" render={() => <Redirect to="/login" />} />
        </Switch>
      </Router>
    );
  }

  // Private routes
  return (
    <Router>
      <Switch>
        <Route path="/login" component={Login} />
        <Route path="/register/:invite" component={Register} />
        <Route path="/register" component={Register} />
        <Route path="/verify" component={EmailVerification} />
        <Route path="/reset-password" component={RequestPasswordReset} />
        <Route path="/reset" component={PasswordReset} />
        <Route
          path="/reset-password-requested"
          component={PasswordResetRequested}
        />
        <Route path="/demo" component={Demo} />
        <Route path="/pricing" component={Pricing} />
        <Route path="/" component={Dashboard} />
        <Route path="*" render={() => <Redirect to="/conversations" />} />
      </Switch>
    </Router>
  );
};

export default App;
