% Copyright (C) 2022 All rights reserved.
% Authors:     Seonghyeon Jo <cpsc.seonghyeon@gmail.com>
%
% Date:         Feb, 07, 2022
% Last Updated: Feb, 07, 2022
% 
% -------------------------------------------------
% 
%
% -------------------------------------------------
%
% the following code has been tested on bar_kappaatlab 2021a
%%
clc; clear all;
addpath(genpath('.'));

% simulation setup
sim_period = 0.001;
t = 0:sim_period:10;
sample_size = size(t, 2);

% parameter of prescribed-performance
global beta rho_infty rho_0 upper_kappa lower_kappa
beta            = 5;                    
rho_infty       = 0.1;
rho_0           = pi/2;
upper_kappa     = 1;
lower_kappa     = 1;

% intial state
x(:,1) = [pi/4; -pi/4; 0; 0;];
qdd = zeros(2,1);

for i=1:sample_size
    % state
    q  = x(1:2,i);
    qd = x(3:4,i);
    if i~= 1
        qdd = (x(3:4,i) - x(3:4,i-1))/0.001;
    end
    
    % trajectory tracking errors
    e(:, i)  = 0 - q;
    ed(:, i) = 0 - qd;
    edd(:, i) = 0 - qdd;
    
    % model 
    M = get_MassMatrix(q);
    C = get_CoriolisVector(q, qd);
    G = get_GravityVector(q);
    F = get_FrictionVector(qd);
    
    % define of prescribed performance function
    rho = ppf(t(i),beta,rho_0,rho_infty);
    
    % dynamics of transformed error
    for j=1:2
        tq(j) = e(j, i)./rho;
        ups(j) =  (1/(2*rho))*((1./(tq(j)+lower_kappa))-(1./(tq(j)-upper_kappa)));
        % z(j) = (1/2)*log((lower_kappa + tq(j))./(upper_kappa - tq(j)));
    end
    ups_m = diag(ups);
    
    
    % input
    % U(:,i) = (G+C+F) + kp*e(:,i) + kd*ed(:,i); % simple pid
    % U(:,i) = (G+C+F)+L1*z'+L2*z_dot'; % simple ppc pid
    % U(:,i) = ueq + (G+C+F)+L1*z'+L2*z_dot';
    
    tol =14;
    ptol = 1e-6;
    U_r(:,i) = G+C+F;  % real U_eq
    % U(:,i) = (G+C+F)+(rand(2,1)*1e-16); % noise U_eq 
    % U(:,i) = (ups_m/(M))\(ups_m/M)*(C+G+F); % using mldivide or mrdivide
    U(:,i) = round((round(ups_m/M,tol))\(round(ups_m/M,tol)),tol)*(C+G+F); % using round and mldivide or mrdivide
    % U(:,i) = inv(ups_m*inv(M))*(ups_m*inv(M))*(C+G+F); % using inverse
    % U(:,i) = pinv(ups_m*pinv(M,ptol),ptol)*(ups_m*pinv(M,ptol))*(C+G+F); % using pinv 
    
    % matrix test
    % AA = inv(ups_m*inv(M))*(ups_m*inv(M));
    % AA = (ups_m/(M))\(ups_m/M);%
    AA = round((round(ups_m/M,tol))\(round(ups_m/M,tol)),tol);
    % AA = pinv(ups_m*pinv(M,ptol),ptol)*(ups_m*pinv(M,ptol));
    AA1(i) = AA(1);
    AA2(i) = AA(2);
    AA3(i) = AA(3);
    AA4(i) = AA(4);
    
    % rk
    [next_state] = rk(x(:,i), U(:,i),sim_period);
    if i ~= sample_size
        x(:,i+1) = next_state;
    end
    rho_table(i) = rho;
end

% plot
% figure 1 : q
figure(1)
tiledlayout(2,1,'TileSpacing','Compact','Padding','Compact');
set(gcf,'color','w');
for i=1:2
    ax = nexttile;
    plot(t, ones(sample_size,1)*(x(i,1))*180/pi,'-k','LineWidth',1.5');
    hold on
    plot(t, x(i,:)*180/pi,'-.r','LineWidth',1.5');
    hold off
    ylim([ax.YLim(1)-0.025  ax.YLim(2)+0.025])
    xlim([0 sample_size*0.001])
    xlabel('time(s)', 'FontSize', 10)
    ylabel("q_{"+i+ "}(rad)", 'FontSize', 10);
    grid on;
    legend('qd', 'q')
end
% saveas(gcf,"fig\q_result.png");

% figure 2 : input
figure(2)
tiledlayout(2,1,'TileSpacing','Compact','Padding','Compact');
set(gcf,'color','w');
for i=1:2
    ax = nexttile;
    plot(t, U(i,:),'-k','LineWidth',1.5');
    ylim([ax.YLim(1)-0.025  ax.YLim(2)+0.025])
    xlim([0 sample_size*0.001])
    xlabel('time(s)', 'FontSize', 10)
    ylabel("u_{"+i+ "}(Nm)", 'FontSize', 10);
    grid on;
    legend('u')
end
saveas(gcf,"fig\u_result.png");
% 
% % figure 3 : z
% figure(3)
% tiledlayout(2,1,'TileSpacing','Compact','Padding','Compact');
% set(gcf,'color','w');
% for i=1:2
%     ax = nexttile;
%     hold off;
%     plot(t,z_table(i,:),'-k','LineWidth',1.5');
%     hold on;
%     plot(t, -rho_table,':b','LineWidth',1.5');
%     plot(t, rho_table,':b','LineWidth',1.5');
%     % plot(t,z(i,:),'-k','LineWidth',1.5');
%     plot(t, zeros(sample_size,1),':k','LineWidth',1');
%     plot(t, rho_infty*ones(sample_size,1),'-.r','LineWidth',1.5');
%     plot(t, -rho_infty*ones(sample_size,1),'-.r','LineWidth',1.5');
% %     ylim([-rho_infty*6 rho_infty*6])
%     xlim([0 sample_size*0.001])
%     xlabel('time[s]', 'FontSize', 10)
%     ylabel("z_{"+i+ "}[rad]", 'FontSize', 10);
%     grid on;
%     legend('z')
% end
% saveas(gcf,"fig\z_result.png");

% B matrix Test noise
figure(4)
tiledlayout(2,1,'TileSpacing','Compact','Padding','Compact');
set(gcf,'color','w');
hold off;
plot(t,1-AA1,':k','LineWidth',1.5');
hold on;
plot(t,AA2,':k','LineWidth',1.5');
plot(t,AA3,':k','LineWidth',1.5');
plot(t,1-AA4,':k','LineWidth',1.5');
% plot(t,AAE(1,:),':k','LineWidth',1.5');
% plot(t,AAE(2,:),':k','LineWidth',1.5');
grid on;

