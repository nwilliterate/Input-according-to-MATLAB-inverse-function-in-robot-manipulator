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

inverse_type = 4;
if inverse_type == 1
    % using inverse function
    file_name = "1.inv";
elseif inverse_type == 2
    % using Moore-Penrose pseudoinverse function
    file_name = "2.pinv";
    ptol = 1e-14; % singular value tolerance 1e-14
elseif inverse_type == 3
    % using mldivide, mrdivide function
    file_name = "3.mlr-divide"; 
elseif inverse_type == 4
    % using round, mldivide, mrdivide function
    file_name = "4.mlr-divide-round";
    tol =14; % number of digits to the nearest multiple of 10-N.
elseif inverse_type == 0
    % nothing
    file_name = "0";
end
    
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
    end
    ups_m = diag(ups);
   
    % input test
    Ur(:,i) = G+C+F;  % real U_eq
    
    % B matrix calculation according to the inverse function
    if inverse_type == 1
        B = inv(ups_m*inv(M))*(ups_m*inv(M));
    elseif inverse_type == 2
        B = pinv(ups_m*pinv(M,ptol),ptol)*(ups_m*pinv(M,ptol));
    elseif inverse_type == 3
        B = (ups_m/(M))\(ups_m/M);
    elseif inverse_type == 4
        B = round((round(ups_m/M,tol))\(round(ups_m/M,tol)),tol);
    elseif inverse_type == 0
        B = eye(2);
    end 
    
    U(:,i) = B*(G+C+F);
    
    % matrix test
    AA1(i) = B(1);
    AA2(i) = B(2);
    AA3(i) = B(3);
    AA4(i) = B(4);
    
    % rk
    [next_state] = rk(x(:,i), U(:,i),sim_period);
    if i ~= sample_size
        x(:,i+1) = next_state;
    end
end

mean(Ur(:,i)-U(:,i),2)

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
saveas(gcf,"fig\"+file_name+"_q_result.png");

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
saveas(gcf,"fig\"+file_name+"_u_result.png");

% B matrix Test noise
figure(3)
tiledlayout(2,1,'TileSpacing','Compact','Padding','Compact');
set(gcf,'color','w');
hold off;
plot(t,1-AA1,':k','LineWidth',1.5');
hold on;
plot(t,AA2,':k','LineWidth',1.5');
plot(t,AA3,':k','LineWidth',1.5');
plot(t,1-AA4,':k','LineWidth',1.5');
xlabel('time(s)', 'FontSize', 10)
ylabel("Err", 'FontSize', 10);
grid on;
saveas(gcf,"fig\"+file_name+"_e_result.png");
