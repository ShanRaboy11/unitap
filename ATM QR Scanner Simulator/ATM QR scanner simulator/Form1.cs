using AForge.Video;
using AForge.Video.DirectShow;
using Newtonsoft.Json;
using Newtonsoft.Json.Linq;
using Postgrest.Client;
using Supabase;
using Supabase.Postgrest.Attributes;
using Supabase.Postgrest.Models;
using System;
using System.Collections.Generic;
using System.Drawing;
using System.Linq;
using System.Net.Http;
using System.Net.Http.Json;
using System.Text;
using System.Threading.Tasks;
using System.Windows.Forms;
using System.Xml.Linq;
using ZXing;
using ZXing.Windows.Compatibility;

namespace ATM_QR_scanner_simulator
{
    public partial class frmMainATM : Form
    {
        private static readonly HttpClient httpClient = new HttpClient();
        // Camera related variables
        private FilterInfoCollection videoDevices;
        private VideoCaptureDevice videoSource;

        // UI Controls
        private PictureBox picCamera;
        private Button btnStartStop;
        private Label lblStatus;
        private TextBox txtTransactionDetails;
        private Button btnConfirm;
        private Button btnCancel;

        // Hardware simulation components
        private ProgressBar progressBar;
        private Label lblHardwareStatus;
        private QRTransactionData currentTransaction;

        // NEW: ATM System Components
        private Panel pnlEntryPoint;
        private Panel pnlBankSelection;
        private Panel pnlPinEntry;
        private Panel pnlMainMenu;
        private Panel pnlQRScanner;

        // NEW: Database and UPI Components
        private Supabase.Client supabase;
        private List<BankPartner> partnerBanks;
        private string currentAccountNumber;
        private decimal currentBalance;
        private string currentBankCode;

        public frmMainATM()
        {
            InitializeComponent();
            Load += frmMainATM_Load;
        }

        private void frmMainATM_Load(object sender, EventArgs e)
        {
            InitializeSupabase();
            InitializePartnerBanks();
            SetupEntryPoint();
            CheckCamera();
        }

        private async void InitializeSupabase()
        {
            try
            {
                var url = "https://jwoxcantwdpnyastialx.supabase.co";
                var key = "eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6Imp3b3hjYW50d2Rwbnlhc3RpYWx4Iiwicm9sZSI6ImFub24iLCJpYXQiOjE3NjQxNzU5NzEsImV4cCI6MjA3OTc1MTk3MX0.pEW51x5h0arI7VrokZf793DhCGKSTqE51dax2xnZqoE";

                var options = new Supabase.SupabaseOptions
                {
                    AutoConnectRealtime = true
                };

                supabase = new Supabase.Client(url, key, options);
                await supabase.InitializeAsync();
            }
            catch (Exception ex)
            {
                MessageBox.Show($"Database connection failed: {ex.Message}\nUsing offline mode.");
            }
        }

        private void InitializePartnerBanks()
        {
            partnerBanks = new List<BankPartner>
            {
                new BankPartner { BankCode = "BOC", BankName = "Bank of City", Logo = "🏦" },
                new BankPartner { BankCode = "NBC", BankName = "National Bank Co.", Logo = "💰" },
                new BankPartner { BankCode = "PTC", BankName = "Peoples Trust Bank", Logo = "🔒" },
                new BankPartner { BankCode = "GLB", BankName = "Global Bank Inc.", Logo = "🌍" },
                new BankPartner { BankCode = "QTB", BankName = "Quick Transfer Bank", Logo = "⚡" },
                new BankPartner { BankCode = "STB", BankName = "Secure Trust Bank", Logo = "🛡️" }
            };
        }

        // ==================== ENTRY POINT SYSTEM ====================
        private void SetupEntryPoint()
        {
            pnlEntryPoint = new Panel();
            pnlEntryPoint.Size = new Size(800, 600);
            pnlEntryPoint.Location = new Point(50, 50);
            pnlEntryPoint.BackColor = Color.LightGray;
            this.Controls.Add(pnlEntryPoint);

            // Title
            var lblTitle = new Label();
            lblTitle.Text = "Welcome to Smart ATM";
            lblTitle.Font = new Font("Arial", 20, FontStyle.Bold);
            lblTitle.Location = new Point(200, 50);
            lblTitle.Size = new Size(400, 40);
            lblTitle.TextAlign = ContentAlignment.MiddleCenter;
            pnlEntryPoint.Controls.Add(lblTitle);

            // Traditional ATM Entry Button
            var btnTraditional = new Button();
            btnTraditional.Text = "Traditional ATM\n(PIN & Menu)";
            btnTraditional.Font = new Font("Arial", 14);
            btnTraditional.Location = new Point(150, 150);
            btnTraditional.Size = new Size(200, 120);
            btnTraditional.BackColor = Color.LightBlue;
            btnTraditional.Click += (s, e) => ShowTraditionalEntry();
            pnlEntryPoint.Controls.Add(btnTraditional);

            // Quick QR Entry Button
            var btnQuickQR = new Button();
            btnQuickQR.Text = "Quick QR Scan\n(Fast Transaction)";
            btnQuickQR.Font = new Font("Arial", 14);
            btnQuickQR.Location = new Point(450, 150);
            btnQuickQR.Size = new Size(200, 120);
            btnQuickQR.BackColor = Color.LightGreen;
            btnQuickQR.Click += (s, e) => ShowQuickQREntry();
            pnlEntryPoint.Controls.Add(btnQuickQR);

            // Description labels
            var lblTraditionalDesc = new Label();
            lblTraditionalDesc.Text = "• Enter PIN\n• Choose transaction\n• Full ATM features";
            lblTraditionalDesc.Location = new Point(150, 280);
            lblTraditionalDesc.Size = new Size(200, 80);
            lblTraditionalDesc.Font = new Font("Arial", 10);
            pnlEntryPoint.Controls.Add(lblTraditionalDesc);

            var lblQRDesc = new Label();
            lblQRDesc.Text = "• Scan pre-made QR\n• Direct transaction\n• Skip PIN & menu";
            lblQRDesc.Location = new Point(450, 280);
            lblQRDesc.Size = new Size(200, 80);
            lblQRDesc.Font = new Font("Arial", 10);
            pnlEntryPoint.Controls.Add(lblQRDesc);
        }

        private void ShowTraditionalEntry()
        {
            HideAllPanels();
            ShowBankSelection();
        }

        private void ShowQuickQREntry()
        {
            HideAllPanels();
            if (pnlQRScanner == null) SetupQRScanner();
            pnlQRScanner.Visible = true;
            lblStatus.Text = "Scan your pre-approved QR code for quick transaction";
            StartCamera();
        }

        // ==================== BANK SELECTION SYSTEM ====================
        private void ShowBankSelection()
        {
            if (pnlBankSelection == null) SetupBankSelection();
            pnlBankSelection.Visible = true;
        }

        private void SetupBankSelection()
        {
            pnlBankSelection = new Panel();
            pnlBankSelection.Size = new Size(800, 600);
            pnlBankSelection.Location = new Point(50, 50);
            pnlBankSelection.Visible = false;
            this.Controls.Add(pnlBankSelection);

            // Header
            var lblHeader = new Label();
            lblHeader.Text = "Select Your Bank";
            lblHeader.Font = new Font("Arial", 18, FontStyle.Bold);
            lblHeader.Location = new Point(300, 30);
            lblHeader.Size = new Size(200, 40);
            lblHeader.TextAlign = ContentAlignment.MiddleCenter;
            pnlBankSelection.Controls.Add(lblHeader);

            var lblSubHeader = new Label();
            lblSubHeader.Text = "Unified Payments Interface - Partner Banks";
            lblSubHeader.Font = new Font("Arial", 12);
            lblSubHeader.Location = new Point(250, 70);
            lblSubHeader.Size = new Size(300, 25);
            lblSubHeader.TextAlign = ContentAlignment.MiddleCenter;
            pnlBankSelection.Controls.Add(lblSubHeader);

            // Back button
            var btnBack = new Button();
            btnBack.Text = "← Back";
            btnBack.Location = new Point(20, 20);
            btnBack.Size = new Size(80, 30);
            btnBack.Click += (s, e) => ReturnToEntryPoint();
            pnlBankSelection.Controls.Add(btnBack);

            // Create bank selection grid
            int buttonWidth = 180;
            int buttonHeight = 80;
            int spacing = 20;
            int startX = 100;
            int startY = 120;

            for (int i = 0; i < partnerBanks.Count; i++)
            {
                var bank = partnerBanks[i];
                var btnBank = new Button();
                btnBank.Size = new Size(buttonWidth, buttonHeight);
                btnBank.Location = new Point(
                    startX + (i % 3) * (buttonWidth + spacing),
                    startY + (i / 3) * (buttonHeight + spacing)
                );
                btnBank.Text = $"{bank.Logo}\n{bank.BankName}";
                btnBank.Font = new Font("Arial", 10);
                btnBank.Tag = bank.BankCode;
                btnBank.BackColor = Color.LightBlue;
                btnBank.Click += BankButton_Click;
                pnlBankSelection.Controls.Add(btnBank);
            }
        }

        private void BankButton_Click(object sender, EventArgs e)
        {
            var button = (Button)sender;
            string selectedBankCode = button.Tag.ToString();
            var selectedBank = partnerBanks.Find(b => b.BankCode == selectedBankCode);

            currentBankCode = selectedBankCode;
            ShowPinEntry(selectedBank.BankName);
        }

        // ==================== PIN ENTRY SYSTEM ====================
        private void ShowPinEntry(string bankName)
        {
            HideAllPanels();
            if (pnlPinEntry == null) SetupPinEntry();

            // Update PIN entry header with bank name
            var lblBankHeader = pnlPinEntry.Controls.OfType<Label>()
                .FirstOrDefault(l => l.Name == "lblBankHeader");

            if (lblBankHeader != null)
            {
                lblBankHeader.Text = $"{bankName} - Enter PIN";
            }

            pnlPinEntry.Visible = true;
        }

        private void SetupPinEntry()
        {
            pnlPinEntry = new Panel();
            pnlPinEntry.Size = new Size(400, 500);
            pnlPinEntry.Location = new Point(250, 100);
            pnlPinEntry.Visible = false;
            this.Controls.Add(pnlPinEntry);

            // Back button
            var btnBack = new Button();
            btnBack.Text = "← Change Bank";
            btnBack.Location = new Point(0, 0);
            btnBack.Size = new Size(120, 30);
            btnBack.Click += (s, e) => ShowBankSelection();
            pnlPinEntry.Controls.Add(btnBack);

            // Bank header
            var lblBankHeader = new Label();
            lblBankHeader.Name = "lblBankHeader";
            lblBankHeader.Text = "Bank - Enter PIN";
            lblBankHeader.Location = new Point(100, 30);
            lblBankHeader.Size = new Size(200, 25);
            lblBankHeader.Font = new Font("Arial", 12, FontStyle.Bold);
            lblBankHeader.TextAlign = ContentAlignment.MiddleCenter;
            pnlPinEntry.Controls.Add(lblBankHeader);

            // PIN Display
            var txtPinEntry = new TextBox();
            txtPinEntry.Name = "txtPinEntry";
            txtPinEntry.Location = new Point(100, 80);
            txtPinEntry.Size = new Size(200, 40);
            txtPinEntry.Font = new Font("Arial", 16);
            txtPinEntry.PasswordChar = '•';
            txtPinEntry.TextAlign = HorizontalAlignment.Center;
            txtPinEntry.MaxLength = 4;
            txtPinEntry.ReadOnly = true;
            pnlPinEntry.Controls.Add(txtPinEntry);

            // Number Pad
            int buttonSize = 60;
            int numSpacing = 10;
            int numStartX = 100;
            int numStartY = 140;

            // Create number buttons 1-9
            for (int i = 1; i <= 9; i++)
            {
                var btn = new Button();
                btn.Size = new Size(buttonSize, buttonSize);
                btn.Location = new Point(
                    numStartX + ((i - 1) % 3) * (buttonSize + numSpacing),
                    numStartY + ((i - 1) / 3) * (buttonSize + numSpacing)
                );
                btn.Text = i.ToString();
                btn.Font = new Font("Arial", 14);
                btn.Tag = i;
                btn.Click += NumberButton_Click;
                pnlPinEntry.Controls.Add(btn);
            }

            // Button 0
            var btnNumber0 = new Button();
            btnNumber0.Size = new Size(buttonSize, buttonSize);
            btnNumber0.Location = new Point(numStartX + buttonSize + numSpacing, numStartY + 3 * (buttonSize + numSpacing));
            btnNumber0.Text = "0";
            btnNumber0.Font = new Font("Arial", 14);
            btnNumber0.Tag = 0;
            btnNumber0.Click += NumberButton_Click;
            pnlPinEntry.Controls.Add(btnNumber0);

            // Clear Button
            var btnClear = new Button();
            btnClear.Size = new Size(buttonSize, buttonSize);
            btnClear.Location = new Point(numStartX, numStartY + 3 * (buttonSize + numSpacing));
            btnClear.Text = "C";
            btnClear.Font = new Font("Arial", 14);
            btnClear.BackColor = Color.Orange;
            btnClear.Click += (s, e) => {
                var pinBox = pnlPinEntry.Controls.Find("txtPinEntry", true).First() as TextBox;
                pinBox.Text = "";
            };
            pnlPinEntry.Controls.Add(btnClear);

            // Enter Button
            var btnEnter = new Button();
            btnEnter.Size = new Size(buttonSize, buttonSize);
            btnEnter.Location = new Point(numStartX + 2 * (buttonSize + numSpacing), numStartY + 3 * (buttonSize + numSpacing));
            btnEnter.Text = "✓";
            btnEnter.Font = new Font("Arial", 14);
            btnEnter.BackColor = Color.LightGreen;
            btnEnter.Click += BtnEnterPin_Click;
            pnlPinEntry.Controls.Add(btnEnter);
        }

        private void NumberButton_Click(object sender, EventArgs e)
        {
            var button = (Button)sender;
            var txtPinEntry = pnlPinEntry.Controls.Find("txtPinEntry", true).First() as TextBox;

            if (txtPinEntry.Text.Length < 4)
            {
                txtPinEntry.Text += button.Tag.ToString();
            }
        }

        private async void BtnEnterPin_Click(object sender, EventArgs e)
        {
            var txtPinEntry = pnlPinEntry.Controls.Find("txtPinEntry", true).First() as TextBox;

            if (txtPinEntry.Text.Length != 4)
            {
                MessageBox.Show("Please enter 4-digit PIN");
                return;
            }

            try
            {
                // NEW: Validate with Supabase
                var result = await supabase.From<Profile>()
                    .Where(x => x.PinHash == HashPin(txtPinEntry.Text))
                    .Single();

                if (result != null)
                {
                    var account = await supabase.From<Wallet>()
                        .Where(x => x.UserId == result.Id && result.PinHash == HashPin(txtPinEntry.Text))
                        .Single();
                    currentAccountNumber = account.UserId.ToString();
                    currentBalance = account.Balance;
                    ShowMainMenu();
                }
                else
                {
                    MessageBox.Show("Invalid PIN");
                    txtPinEntry.Text = "";
                }
            }
            catch (Exception ex)
            {
                // Fallback for demo
                currentAccountNumber = "123456789";
                currentBalance = 1000.00m;
                ShowMainMenu();
            }
        }

        private string HashPin(string pin)
        {
            // Simple hash for demo - use proper hashing in production
            return $"hashed_pin_{pin}";
        }

        // ==================== MAIN MENU SYSTEM ====================
        private void ShowMainMenu()
        {
            HideAllPanels();
            if (pnlMainMenu == null) SetupMainMenu();
            pnlMainMenu.Visible = true;
        }

        private void SetupMainMenu()
        {
            pnlMainMenu = new Panel();
            pnlMainMenu.Size = new Size(600, 400);
            pnlMainMenu.Location = new Point(150, 100);
            pnlMainMenu.Visible = false;
            this.Controls.Add(pnlMainMenu);

            // Welcome Label
            var lblWelcome = new Label();
            lblWelcome.Text = $"Welcome! Account: {currentAccountNumber}\nBalance: ${currentBalance:F2}";
            lblWelcome.Location = new Point(50, 20);
            lblWelcome.Size = new Size(500, 40);
            lblWelcome.Font = new Font("Arial", 12);
            pnlMainMenu.Controls.Add(lblWelcome);

            // Transaction Buttons
            CreateMenuButton("Withdraw", 50, 80, Color.LightBlue, (s, e) => ProcessTransaction("withdrawal"));
            CreateMenuButton("Deposit", 50, 140, Color.LightGreen, (s, e) => ProcessTransaction("deposit"));
            CreateMenuButton("Transfer", 50, 200, Color.LightYellow, (s, e) => ProcessTransaction("transfer"));
            CreateMenuButton("Balance Inquiry", 50, 260, Color.LightGray, (s, e) => ShowBalance());
            CreateMenuButton("Quick QR Scan", 300, 80, Color.LightCyan, (s, e) => ShowQuickQREntry());
            CreateMenuButton("Logout", 300, 260, Color.LightCoral, (s, e) => Logout());
        }

        private void CreateMenuButton(string text, int x, int y, Color color, EventHandler clickHandler)
        {
            var button = new Button();
            button.Text = text;
            button.Location = new Point(x, y);
            button.Size = new Size(200, 50);
            button.BackColor = color;
            button.Font = new Font("Arial", 11);
            button.Click += clickHandler;
            pnlMainMenu.Controls.Add(button);
        }

        // ==================== QR SCANNER SYSTEM ====================
        private void SetupQRScanner()
        {
            pnlQRScanner = new Panel();
            pnlQRScanner.Size = this.ClientSize;
            pnlQRScanner.Location = new Point(0, 0);
            pnlQRScanner.BackColor = Color.LightGray;
            pnlQRScanner.Visible = false;
            this.Controls.Add(pnlQRScanner);

            // Back button
            var btnBack = new Button();
            btnBack.Text = "← Back to Main";
            btnBack.Location = new Point(20, 20);
            btnBack.Size = new Size(120, 30);
            btnBack.BackColor = Color.White;
            btnBack.Click += (s, e) => ReturnToEntryPoint();
            pnlQRScanner.Controls.Add(btnBack);

            // Camera preview - properly sized and positioned
            picCamera = new PictureBox();
            picCamera.Location = new Point(50, 80);
            picCamera.Size = new Size(600, 450);
            picCamera.BorderStyle = BorderStyle.FixedSingle;
            picCamera.SizeMode = PictureBoxSizeMode.StretchImage;
            picCamera.BackColor = Color.Black;
            pnlQRScanner.Controls.Add(picCamera);

            // Status label
            lblStatus = new Label();
            lblStatus.Location = new Point(160, 555);
            lblStatus.Size = new Size(400, 25);
            lblStatus.Text = "Click 'Start Camera' to begin QR scanning";
            lblStatus.Font = new Font("Arial", 10);
            pnlQRScanner.Controls.Add(lblStatus);

            // Transaction details panel
            var detailsPanel = new Panel();
            detailsPanel.Location = new Point(670, 80);
            detailsPanel.Size = new Size(300, 500);
            detailsPanel.BackColor = Color.White;
            detailsPanel.BorderStyle = BorderStyle.FixedSingle;
            pnlQRScanner.Controls.Add(detailsPanel);

            // Transaction details display inside the panel
            txtTransactionDetails = new TextBox();
            txtTransactionDetails.Location = new Point(10, 40);
            txtTransactionDetails.Size = new Size(280, 200);
            txtTransactionDetails.Multiline = true;
            txtTransactionDetails.ScrollBars = ScrollBars.Vertical;
            txtTransactionDetails.ReadOnly = true;
            txtTransactionDetails.Text = "Transaction details will appear here...";
            detailsPanel.Controls.Add(txtTransactionDetails);

            // Details label
            var lblDetails = new Label();
            lblDetails.Text = "Transaction Details:";
            lblDetails.Location = new Point(10, 10);
            lblDetails.Size = new Size(200, 20);
            lblDetails.Font = new Font("Arial", 10, FontStyle.Bold);
            detailsPanel.Controls.Add(lblDetails);

            // Start/Stop camera button
            btnStartStop = new Button();
            btnStartStop.Location = new Point(50, 550);
            btnStartStop.Size = new Size(100, 30);
            btnStartStop.Text = "Start Camera";
            btnStartStop.BackColor = Color.LightBlue;
            btnStartStop.Click += BtnStartStop_Click;
            pnlQRScanner.Controls.Add(btnStartStop);

            // Confirm transaction button
            btnConfirm = new Button();
            btnConfirm.Location = new Point(10, 250);
            btnConfirm.Size = new Size(130, 35);
            btnConfirm.Text = "Confirm";
            btnConfirm.BackColor = Color.LightGreen;
            btnConfirm.Click += BtnConfirm_Click;
            btnConfirm.Enabled = false;
            detailsPanel.Controls.Add(btnConfirm);

            // Cancel transaction button
            btnCancel = new Button();
            btnCancel.Location = new Point(150, 250);
            btnCancel.Size = new Size(130, 35);
            btnCancel.Text = "Cancel";
            btnCancel.BackColor = Color.LightCoral;
            btnCancel.Click += BtnCancel_Click;
            detailsPanel.Controls.Add(btnCancel);

            // Hardware progress bar
            progressBar = new ProgressBar();
            progressBar.Location = new Point(50, 600);
            progressBar.Size = new Size(600, 20);
            progressBar.Visible = false;
            pnlQRScanner.Controls.Add(progressBar);

            // Hardware status label
            lblHardwareStatus = new Label();
            lblHardwareStatus.Location = new Point(50, 625);
            lblHardwareStatus.Size = new Size(600, 30);
            lblHardwareStatus.Text = "Hardware status: Ready";
            lblHardwareStatus.Font = new Font("Arial", 10);
            pnlQRScanner.Controls.Add(lblHardwareStatus);
        }

        // ==================== EXISTING QR FUNCTIONALITY (UPDATED) ====================
        private void CheckCamera()
        {
            videoDevices = new FilterInfoCollection(FilterCategory.VideoInputDevice);
            if (videoDevices.Count == 0)
            {
                lblStatus.Text = "No camera found! Using simulated mode.";
            }
            else
            {
                lblStatus.Text = $"Found {videoDevices.Count} camera(s). Ready to start.";
            }
        }

        private void StartCamera()
        {
            try
            {
                if (videoDevices.Count == 0)
                {
                    MessageBox.Show("No camera detected. Please connect a camera.");
                    return;
                }

                videoSource = new VideoCaptureDevice(videoDevices[1].MonikerString); //ALWAYS at index 1
                videoSource.NewFrame += VideoSource_NewFrame;
                videoSource.Start();

                btnStartStop.Text = "Stop Camera";
                lblStatus.Text = "Camera started. Point QR code at camera...";
                btnConfirm.Enabled = false;
            }
            catch (Exception ex)
            {
                MessageBox.Show($"Error starting camera: {ex.Message}");
            }
        }

        private void StopCamera()
        {
            if (videoSource != null && videoSource.IsRunning)
            {
                videoSource.SignalToStop();
                videoSource.NewFrame -= VideoSource_NewFrame;
                videoSource = null;
                picCamera.Image = null;
                btnStartStop.Text = "Start Camera";
                lblStatus.Text = "Camera stopped.";
            }
        }

        private void VideoSource_NewFrame(object sender, NewFrameEventArgs eventArgs)
        {
            try
            {
                Bitmap bitmap = (Bitmap)eventArgs.Frame.Clone();
                var reader = new BarcodeReaderGeneric();
                reader.Options.TryHarder = true;
                LuminanceSource luminance = new ZXing.Windows.Compatibility.BitmapLuminanceSource(bitmap);
                Result result = reader.Decode(luminance);

                if (result != null)
                {
                    this.Invoke(new Action(() => ProcessQRCode(result, bitmap)));
                }
                else
                {
                    this.Invoke(new Action(() => picCamera.Image = bitmap));
                }
            }
            catch (Exception ex)
            {
                System.Diagnostics.Debug.WriteLine($"Error processing frame: {ex.Message}");
            }
        }

        // UPDATED: QR Processing with Supabase integration
        private async void ProcessQRCode(Result result, Bitmap bitmap)
        {
            try
            {
                StopCamera();
                picCamera.Image = bitmap;
                lblStatus.Text = "QR Code detected! Processing...";

                // DEBUG: See what's actually being read
                Console.WriteLine($"QR Raw Content: '{result.Text}'");

                QRTransactionData qrData = null;

                // Try to parse as JSON
                try
                {
                    qrData = JsonConvert.DeserializeObject<QRTransactionData>(result.Text);

                    // Validate QR session with Supabase
                    var session = await supabase.From<AtmQrToken>()
                        .Where(x => x.TokenSignature == qrData.TokenSignature || x.Id == qrData.UserId)
                        .Single();

                    if (session == null)
                    {
                        MessageBox.Show("Invalid or expired QR session.");
                        return;
                    }

                    // Update session status
                    session.IsScanned = true;
                    await session.Update<AtmQrToken>();

                    // Set current transaction for processing
                    currentTransaction = new QRTransactionData
                    {
                        UserId = qrData.UserId,
                        Amount = qrData.Amount,
                        TransactionType = qrData.TransactionType,
                        ToAccount = qrData.ToAccount,
                        CreatedAt = DateTime.Now
                    };

                    DisplayTransactionDetails(currentTransaction);
                    btnConfirm.Enabled = true;
                    lblStatus.Text = "QR processed. Review and click Confirm.";
                }
                catch (JsonException jsonEx)
                {
                    MessageBox.Show($"Invalid JSON format: {jsonEx.Message}\n\nContent: {result.Text}");
                    return;
                }
                catch (Exception ex)
                {
                    MessageBox.Show($"Error processing QR: {ex.Message}");
                    return;
                }
            }
            catch (Exception ex)
            {
                MessageBox.Show($"Error processing QR: {ex.Message}");
            }
        }

        private bool IsValidJson(string strInput)
        {
            if (string.IsNullOrWhiteSpace(strInput)) return false;

            strInput = strInput.Trim();

            // Check if it starts with { and ends with } (object) or [ and ] (array)
            if ((strInput.StartsWith("{") && strInput.EndsWith("}")) ||
                (strInput.StartsWith("[") && strInput.EndsWith("]")))
            {
                try
                {
                    var obj = JToken.Parse(strInput);
                    return true;
                }
                catch (JsonReaderException)
                {
                    return false;
                }
                catch (Exception)
                {
                    return false;
                }
            }

            return false;
        }

        private void DisplayTransactionDetails(QRTransactionData transaction)
        {
            string details = $"QR SCAN SUCCESS!\n\n";
            details += $"Account: {transaction.UserId}\n";
            details += $"Amount: ${transaction.Amount:F2}\n";
            details += $"Type: {transaction.TransactionType}\n";
            if (!string.IsNullOrEmpty(transaction.ToAccount))
                details += $"To: {transaction.ToAccount}\n";
            details += $"\nScanned at: {transaction.CreatedAt}";
            txtTransactionDetails.Text = details;
        }

        private void BtnStartStop_Click(object sender, EventArgs e)
        {
            if (videoSource == null || !videoSource.IsRunning)
            {
                StartCamera();
            }
            else
            {
                StopCamera();
            }
        }

        // UPDATED: Transaction processing with Supabase
        private async void BtnConfirm_Click(object sender, EventArgs e)
        {
            try
            {
                btnConfirm.Enabled = false;
                progressBar.Visible = true;
                lblStatus.Text = "Processing transaction...";
                lblHardwareStatus.Text = "Hardware status: Initializing...";

                // NEW: Validate with Supabase
                await ValidateWithBankSystem();

                bool hardwareSuccess = await PerformHardwareOperations();

                if (hardwareSuccess)
                {
                    // NEW: Record transaction in Supabase
                    await RecordTransactionInBlockchain();
                    MessageBox.Show("Transaction completed successfully!", "Success", MessageBoxButtons.OK, MessageBoxIcon.Information);
                }
                else
                {
                    MessageBox.Show("Transaction failed during hardware operations.", "Error", MessageBoxButtons.OK, MessageBoxIcon.Error);
                }

                ResetForm();
            }
            catch (Exception ex)
            {
                MessageBox.Show($"Transaction failed: {ex.Message}", "Error", MessageBoxButtons.OK, MessageBoxIcon.Error);
                ResetForm();
            }
        }

        // NEW: Supabase transaction recording
        private async Task RecordTransactionInBlockchain()
        {
            try
            {
                if (currentTransaction == null)
                    throw new Exception("No transaction to record.");

                // Build the payload for Fabric REST API
                var payload = new Transaction
                {
                    UserId = currentTransaction.UserId,
                    TransactionType = currentTransaction.TransactionType,
                    Amount = currentTransaction.Amount,
                    ToAccount = currentTransaction.ToAccount,
                    TerminalId = "ATM_001"
                };

                string jsonPayload = JsonConvert.SerializeObject(payload);

                // TODO: Replace with your teammate's actual Fabric REST endpoint
                string fabricEndpoint = "https://owen-discarnate-superindulgently.ngrok-free.dev/tx/create\r\n";

                var content = new StringContent(jsonPayload, Encoding.UTF8, "application/json");

                HttpResponseMessage response = await httpClient.PostAsync(fabricEndpoint, content);

                if (response.IsSuccessStatusCode)
                {
                    MessageBox.Show("Transaction successfully recorded on the blockchain!", "Success", MessageBoxButtons.OK, MessageBoxIcon.Information);
                }
                else
                {
                    string respText = await response.Content.ReadAsStringAsync();
                    MessageBox.Show($"Failed to record transaction on blockchain.\nStatus: {response.StatusCode}\nResponse: {respText}", "Error", MessageBoxButtons.OK, MessageBoxIcon.Error);

                    // Optional fallback: save locally
                    SaveTransactionLocally();
                }
            }
            catch (Exception ex)
            {
                MessageBox.Show($"Error recording transaction to blockchain: {ex.Message}", "Error", MessageBoxButtons.OK, MessageBoxIcon.Error);
                SaveTransactionLocally();
            }
        }

        private void SaveTransactionLocally()
        {
            string transactionRecord = $@"ATM TRANSACTION COMPLETED SUCCESSFULLY
            ===============================
            Timestamp: {DateTime.Now:yyyy-MM-dd HH:mm:ss}
            Account: {currentTransaction?.UserId}
            Amount: ${currentTransaction?.Amount:F2}
            Type: {currentTransaction?.TransactionType}
            To Account: {currentTransaction?.ToAccount}
            Hardware Operations: COMPLETED
            Blockchain Recorded: FAILED / LOCAL COPY
            ===============================
            ";
            string filename = $"atm_transaction_{DateTime.Now:yyyyMMdd_HHmmss}.txt";
            System.IO.File.WriteAllText(filename, transactionRecord);
        }

        // ==================== UTILITY METHODS ====================
        private void HideAllPanels()
        {
            pnlEntryPoint.Visible = false;
            if (pnlBankSelection != null) pnlBankSelection.Visible = false;
            if (pnlPinEntry != null) pnlPinEntry.Visible = false;
            if (pnlMainMenu != null) pnlMainMenu.Visible = false;
            if (pnlQRScanner != null) pnlQRScanner.Visible = false;
        }

        private void ReturnToEntryPoint()
        {
            HideAllPanels();
            pnlEntryPoint.Visible = true;
            StopCamera();
            currentAccountNumber = null;
            currentTransaction = null;
            currentBankCode = null;
        }

        private void Logout()
        {
            ReturnToEntryPoint();
        }

        private void ProcessTransaction(string transactionType)
        {
            // Placeholder for traditional transaction processing
            MessageBox.Show($"{transactionType} feature coming soon!");
        }

        private void ShowBalance()
        {
            MessageBox.Show($"Current Balance: ${currentBalance:F2}", "Balance Inquiry");
        }

        // ==================== EXISTING HARDWARE METHODS (UNCHANGED) ====================
        private async Task ValidateWithBankSystem()
        {
            UpdateHardwareStatus("Contacting bank network...", 10); await Task.Delay(1000);
            UpdateHardwareStatus("Validating account...", 30); await Task.Delay(800);
            UpdateHardwareStatus("Checking balance...", 60); await Task.Delay(600);
            UpdateHardwareStatus("Transaction approved...", 90); await Task.Delay(400);
            UpdateHardwareStatus("Bank validation complete", 100); await Task.Delay(500);
        }

        private async Task<bool> PerformHardwareOperations()
        {
            try
            {
                if (currentTransaction == null) return false;
                progressBar.Value = 0;
                lblHardwareStatus.Text = "Starting hardware operations...";

                switch (currentTransaction.TransactionType?.ToLower())
                {
                    case "withdrawal": return await ProcessWithdrawal();
                    case "deposit": return await ProcessDeposit();
                    case "transfer": return await ProcessTransfer();
                    default: return await ProcessGenericTransaction();
                }
            }
            catch (Exception ex)
            {
                UpdateHardwareStatus($"Hardware error: {ex.Message}", 0);
                return false;
            }
        }

        private async Task<bool> ProcessWithdrawal()
        {
            UpdateHardwareStatus("Counting cash...", 20); await Task.Delay(1000);
            UpdateHardwareStatus("Verifying cash availability...", 40); await Task.Delay(800);
            UpdateHardwareStatus("Preparing to dispense...", 60); await Task.Delay(600);
            UpdateHardwareStatus($"Dispensing ${currentTransaction.Amount}...", 80); await Task.Delay(1500);
            UpdateHardwareStatus("Cash dispensed successfully", 100); await Task.Delay(500);
            return true;
        }

        private async Task<bool> ProcessDeposit()
        {
            UpdateHardwareStatus("Waiting for cash/check...", 20); await Task.Delay(2000);
            UpdateHardwareStatus("Scanning deposited items...", 40); await Task.Delay(1000);
            UpdateHardwareStatus("Verifying deposit amount...", 60); await Task.Delay(800);
            UpdateHardwareStatus("Processing deposit...", 80); await Task.Delay(600);
            UpdateHardwareStatus("Deposit accepted successfully", 100); await Task.Delay(500);
            return true;
        }

        private async Task<bool> ProcessTransfer()
        {
            UpdateHardwareStatus("Initiating transfer...", 25); await Task.Delay(800);
            UpdateHardwareStatus($"Transferring to {currentTransaction.ToAccount}...", 50); await Task.Delay(1000);
            UpdateHardwareStatus("Verifying recipient...", 75); await Task.Delay(600);
            UpdateHardwareStatus("Transfer completed successfully", 100); await Task.Delay(500);
            return true;
        }

        private async Task<bool> ProcessGenericTransaction()
        {
            UpdateHardwareStatus("Processing transaction...", 30); await Task.Delay(1000);
            UpdateHardwareStatus("Updating account...", 60); await Task.Delay(800);
            UpdateHardwareStatus("Finalizing...", 90); await Task.Delay(600);
            UpdateHardwareStatus("Transaction completed", 100); await Task.Delay(500);
            return true;
        }

        private void UpdateHardwareStatus(string status, int progress)
        {
            if (InvokeRequired)
            {
                Invoke(new Action<string, int>(UpdateHardwareStatus), status, progress);
                return;
            }
            lblHardwareStatus.Text = $"Hardware status: {status}";
            progressBar.Value = progress;
            lblStatus.Text = status;
            Application.DoEvents();
        }

        private void BtnCancel_Click(object sender, EventArgs e)
        {
            ResetForm();
        }

        private void ResetForm()
        {
            if (txtTransactionDetails != null)
                txtTransactionDetails.Text = "Transaction details will appear here...";
            if (btnConfirm != null)
                btnConfirm.Enabled = false;
            if (lblStatus != null)
                lblStatus.Text = "Ready to scan. Click 'Start Camera' to begin.";
            if (lblHardwareStatus != null)
                lblHardwareStatus.Text = "Hardware status: Ready";
            if (picCamera != null)
                picCamera.Image = null;
            if (progressBar != null)
            {
                progressBar.Visible = false;
                progressBar.Value = 0;
            }
            currentTransaction = null;
        }


        protected override void OnFormClosing(FormClosingEventArgs e)
        {
            StopCamera();
            base.OnFormClosing(e);
        }
    }

    // ==================== DATA MODELS ====================
    public class TransactionData
    {
        public Guid UserId { get; set; }
        public decimal Amount { get; set; }
        public string TransactionType { get; set; }
        public string? ToAccount { get; set; }
        public string? RawData { get; set; }
        public DateTime Timestamp { get; set; }
    }

    public class QRTransactionData
    {
        [JsonProperty("token_id")]
        public string TokenId { get; set; }

        [JsonProperty("UserId")]
        public Guid UserId { get; set; }

        [JsonProperty("TokenSignature")]
        public string TokenSignature { get; set; }

        [JsonProperty("TransactionType")]
        public string TransactionType { get; set; }

        [JsonProperty("ToAccount")]
        public string ToAccount { get; set; }

        [JsonProperty("Amount")]
        public decimal Amount { get; set; }

        [JsonProperty("is_scanned")]
        public string IsScanned { get; set; }

        [JsonProperty("created_at")]
        public DateTime CreatedAt { get; set; }

        [JsonProperty("expires_at")]
        public string ExpiresAt { get; set; }
    }

    public class BankPartner
    {
        public string BankCode { get; set; }
        public string BankName { get; set; }
        public string Logo { get; set; }
    }

    // ==================== SUPABASE MODELS ====================

    [Table("profiles")]
    public class Profile : BaseModel
    {
        [PrimaryKey("id")]
        public Guid Id { get; set; }

        [Column("email")]
        public string Email { get; set; }

        [Column("full_name")]
        public string FullName { get; set; }

        [Column("pin_hash")]
        public string PinHash { get; set; }

        [Column("phone_number")]
        public string PhoneNumber { get; set; }

        [Column("created_at")]
        public DateTime CreatedAt { get; set; }
    }

    [Table("wallets")]
    public class Wallet : BaseModel
    {
        [PrimaryKey("id")]
        public Guid Id { get; set; }

        [Column("user_id")]
        public Guid UserId { get; set; }

        [Column("currency_code")]
        public string CurrencyCode { get; set; }

        [Column("balance")]
        public decimal Balance { get; set; }

        [Column("is_primary")]
        public bool IsPrimary { get; set; }

        [Reference(typeof(Profile))]
        public Profile User { get; set; }
    }

    [Table("transactions")]
    public class Transaction : BaseModel
    {
        [PrimaryKey("id")]
        public Guid Id { get; set; }

        [Column("user_id")]
        public Guid UserId { get; set; }

        [Column("amount")]
        public decimal Amount { get; set; }

        [Column("type")]
        public string TransactionType { get; set; }

        [Column("status")]
        public string Status { get; set; }

        [Column("description")]
        public string Description { get; set; }

        [Column("terminal_id")]
        public string TerminalId { get; set; }

        [Column("recipient_id")]
        public string ToAccount { get; set; }

        [Column("qr_generated")]
        public bool QrGenerated { get; set; }

        [Column("ledger_hash")]
        public string LedgerHash { get; set; }

        [Reference(typeof(Profile))]
        public Profile User { get; set; }
    }

    [Table("atm_qr_tokens")]
    public class AtmQrToken : BaseModel
    {
        [PrimaryKey("id")]
        public Guid Id { get; set; }

        [Column("token_signature")]
        public string TokenSignature { get; set; }

        [Column("user_id")]
        public Guid UserId { get; set; }

        [Column("transaction_type")]
        public string TransactionType { get; set; }

        [Column("recipient_id")]
        public string ToAccount { get; set; }

        [Column("amount_locked")]
        public decimal AmountLocked { get; set; }

        [Column("is_scanned")]
        public bool IsScanned { get; set; }

        [Column("expires_at")]
        public DateTime ExpiresAt { get; set; }

        [Reference(typeof(Profile))]
        public Profile User { get; set; }
    }
}