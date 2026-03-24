import { Alert } from 'react-bootstrap';

function AlertMessage({ variant = 'info', message, onClose }) {
  if (!message) return null;

  return (
    <Alert variant={variant} onClose={onClose} dismissible={!!onClose}>
      {message}
    </Alert>
  );
}

export default AlertMessage;
